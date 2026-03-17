#!/usr/bin/env python3

import json
import os
import re
import threading
import time
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib import request


DAY_NAMES = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
EVENT_TONES = {
    'break': 'energy_alarm.wav',
    'lunch': 'lunch_bell.wav',
    'shift': 'shift_change.wav',
}
TIME_RE = re.compile(r'^(?:[01]\d|2[0-3]):[0-5]\d$')

STATE_DIR = Path(os.environ.get('FACTORY_ALARM_STATE_DIR', '/var/lib/factory_alarm'))
SCHEDULE_PATH = Path(os.environ.get('FACTORY_ALARM_SCHEDULE_PATH', str(STATE_DIR / 'schedule.json')))
MOPIDY_RPC_URL = os.environ.get('FACTORY_ALARM_MOPIDY_RPC_URL', 'http://127.0.0.1:6680/mopidy/rpc')
BIND_HOST = os.environ.get('FACTORY_ALARM_BIND_HOST', '127.0.0.1')
BIND_PORT = int(os.environ.get('FACTORY_ALARM_BIND_PORT', '8787'))
PLAY_SECONDS = int(os.environ.get('FACTORY_ALARM_PLAY_SECONDS', '20'))
WEATHER_ENABLED = os.environ.get('FACTORY_ALARM_WEATHER_ENABLED', 'false').lower() in ('1', 'true', 'yes', 'on')
WEATHER_LAT = os.environ.get('FACTORY_ALARM_WEATHER_LAT', '').strip()
WEATHER_LON = os.environ.get('FACTORY_ALARM_WEATHER_LON', '').strip()
WEATHER_POLL_SECONDS = int(os.environ.get('FACTORY_ALARM_WEATHER_POLL_SECONDS', '60'))
WEATHER_EVENT = os.environ.get('FACTORY_ALARM_WEATHER_EVENT', 'Tornado Warning').strip()
WEATHER_USER_AGENT = os.environ.get(
    'FACTORY_ALARM_WEATHER_USER_AGENT',
    'FactoryAlarm/1.0 (admin01@localhost)',
)


def empty_schedule() -> dict[str, Any]:
    return {
        day: {
            'slots': [
                {'type': 'break', 'start': '', 'end': ''},
                {'type': 'lunch', 'start': '', 'end': ''},
                {'type': 'shift', 'start': '', 'end': ''},
            ]
        }
        for day in DAY_NAMES
    }


def normalize_time(value: Any) -> str:
    if not isinstance(value, str):
        return ''
    value = value.strip()
    return value if TIME_RE.match(value) else ''


def normalize_schedule(data: Any) -> dict[str, Any]:
    schedule = empty_schedule()
    if not isinstance(data, dict):
        return schedule

    for day in DAY_NAMES:
        raw_day = data.get(day, {})
        raw_slots = raw_day.get('slots', []) if isinstance(raw_day, dict) else []
        slots = []
        if isinstance(raw_slots, list):
            for raw_slot in raw_slots:
                if not isinstance(raw_slot, dict):
                    continue
                event_type = raw_slot.get('type')
                if event_type not in EVENT_TONES:
                    continue
                slots.append(
                    {
                        'type': event_type,
                        'start': normalize_time(raw_slot.get('start', '')),
                        'end': normalize_time(raw_slot.get('end', '')),
                    }
                )
        schedule[day] = {'slots': slots}

    return schedule


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + '.tmp')
    temp_path.write_text(json.dumps(data, indent=2), encoding='utf-8')
    temp_path.replace(path)


def mopidy_rpc(method: str, params: dict[str, Any] | None = None) -> Any:
    payload = {
        'jsonrpc': '2.0',
        'id': int(time.time() * 1000),
        'method': method,
    }
    if params is not None:
        payload['params'] = params

    body = json.dumps(payload).encode('utf-8')
    req = request.Request(
        MOPIDY_RPC_URL,
        data=body,
        headers={'Content-Type': 'application/json'},
        method='POST',
    )
    with request.urlopen(req, timeout=10) as response:
        raw = response.read().decode('utf-8')
        parsed = json.loads(raw)

    if parsed.get('error') is not None:
        raise RuntimeError(parsed['error'])

    return parsed.get('result')


def play_tone_for(filename: str, seconds: int) -> None:
    tone_uri = f'file:///var/lib/mopidy/media/{filename}'
    mopidy_rpc('core.tracklist.clear')
    mopidy_rpc('core.tracklist.add', {'uris': [tone_uri]})
    mopidy_rpc('core.playback.play')
    time.sleep(seconds)
    mopidy_rpc('core.playback.stop')


def has_active_weather_event() -> bool:
    if not WEATHER_ENABLED:
        return False
    if not WEATHER_LAT or not WEATHER_LON:
        return False

    url = f'https://api.weather.gov/alerts/active?point={WEATHER_LAT},{WEATHER_LON}'
    req = request.Request(
        url,
        headers={
            'Accept': 'application/geo+json',
            'User-Agent': WEATHER_USER_AGENT,
        },
        method='GET',
    )
    with request.urlopen(req, timeout=15) as response:
        raw = response.read().decode('utf-8')
        payload = json.loads(raw)

    features = payload.get('features', [])
    for feature in features:
        props = feature.get('properties', {}) if isinstance(feature, dict) else {}
        event = props.get('event', '')
        status = props.get('status', '')
        if event == WEATHER_EVENT and status in ('Actual', 'Test'):
            return True

    return False


class ScheduleRuntime:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._schedule = self._load_schedule_from_disk()
        self._last_minute = ''
        self._fired_keys: set[str] = set()
        self._weather_alarm_active = False
        self._weather_last_state: bool | None = None

    def _load_schedule_from_disk(self) -> dict[str, Any]:
        if not SCHEDULE_PATH.exists():
            schedule = empty_schedule()
            atomic_write_json(SCHEDULE_PATH, schedule)
            return schedule

        try:
            raw = json.loads(SCHEDULE_PATH.read_text(encoding='utf-8'))
        except Exception:
            raw = empty_schedule()
        schedule = normalize_schedule(raw)
        atomic_write_json(SCHEDULE_PATH, schedule)
        return schedule

    def get_schedule(self) -> dict[str, Any]:
        with self._lock:
            return json.loads(json.dumps(self._schedule))

    def save_schedule(self, schedule: dict[str, Any]) -> None:
        normalized = normalize_schedule(schedule)
        with self._lock:
            self._schedule = normalized
            self._last_minute = ''
            self._fired_keys.clear()
        atomic_write_json(SCHEDULE_PATH, normalized)

    def tick_forever(self) -> None:
        while True:
            now = datetime.now()
            day = DAY_NAMES[now.weekday()]
            hhmm = f'{now.hour:02d}:{now.minute:02d}'

            with self._lock:
                if hhmm != self._last_minute:
                    self._last_minute = hhmm
                    self._fired_keys.clear()
                slots = list(self._schedule.get(day, {}).get('slots', []))
                weather_active = self._weather_alarm_active

            # Do not play normal schedule tones while tornado warning alarm is active.
            if weather_active:
                time.sleep(1)
                continue

            for index, slot in enumerate(slots):
                start = slot.get('start', '')
                end = slot.get('end', '')
                event_type = slot.get('type', '')
                if event_type not in EVENT_TONES:
                    continue

                if start == hhmm:
                    key = f'{day}|{hhmm}|{event_type}|{index}|start'
                    with self._lock:
                        if key in self._fired_keys:
                            continue
                        self._fired_keys.add(key)

                    threading.Thread(
                        target=self._play_slot,
                        args=(event_type, 'start'),
                        daemon=True,
                    ).start()

                if end == hhmm:
                    key = f'{day}|{hhmm}|{event_type}|{index}|end'
                    with self._lock:
                        if key in self._fired_keys:
                            continue
                        self._fired_keys.add(key)

                    threading.Thread(
                        target=self._play_slot,
                        args=(event_type, 'end'),
                        daemon=True,
                    ).start()

            time.sleep(1)

    def weather_forever(self) -> None:
        if not WEATHER_ENABLED:
            print('Weather monitor disabled', flush=True)
            return

        if not WEATHER_LAT or not WEATHER_LON:
            print('Weather monitor enabled but WEATHER_LAT/WEATHER_LON are not set', flush=True)
            return

        print(
            f'Weather monitor enabled for event "{WEATHER_EVENT}" at {WEATHER_LAT},{WEATHER_LON}',
            flush=True,
        )

        while True:
            try:
                is_active = has_active_weather_event()
                self._handle_weather_state(is_active)
            except Exception as exc:
                print(f'Weather monitor check failed: {exc}', flush=True)
            time.sleep(max(10, WEATHER_POLL_SECONDS))

    def _handle_weather_state(self, is_active: bool) -> None:
        with self._lock:
            if self._weather_last_state == is_active:
                return
            self._weather_last_state = is_active

        if is_active:
            self._start_weather_alarm()
        else:
            self._stop_weather_alarm()

    def _start_weather_alarm(self) -> None:
        with self._lock:
            if self._weather_alarm_active:
                return
            self._weather_alarm_active = True

        try:
            tone_uri = 'file:///var/lib/mopidy/media/tornado_alarm.wav'
            mopidy_rpc('core.tracklist.clear')
            mopidy_rpc('core.tracklist.add', {'uris': [tone_uri]})
            mopidy_rpc('core.tracklist.set_repeat', {'value': True})
            mopidy_rpc('core.playback.play')
            print('Weather alert active: tornado alarm started (repeat ON)', flush=True)
        except Exception as exc:
            print(f'Failed to start weather alarm: {exc}', flush=True)

    def _stop_weather_alarm(self) -> None:
        with self._lock:
            if not self._weather_alarm_active:
                return
            self._weather_alarm_active = False

        try:
            mopidy_rpc('core.tracklist.set_repeat', {'value': False})
            mopidy_rpc('core.playback.stop')
            print('Weather alert cleared: tornado alarm stopped', flush=True)
        except Exception as exc:
            print(f'Failed to stop weather alarm: {exc}', flush=True)

    def _play_slot(self, event_type: str, edge: str) -> None:
        tone = EVENT_TONES[event_type]
        try:
            play_tone_for(tone, PLAY_SECONDS)
            print(f'Played {event_type} ({edge}) -> {tone}', flush=True)
        except Exception as exc:
            print(f'Failed to play {event_type} ({edge}): {exc}', flush=True)


class ScheduleRequestHandler(BaseHTTPRequestHandler):
    runtime: ScheduleRuntime

    def _send_json(self, status_code: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload).encode('utf-8')
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path == '/health':
            self._send_json(200, {'ok': True})
            return
        if self.path == '/api/schedule':
            self._send_json(200, self.runtime.get_schedule())
            return
        self._send_json(404, {'error': 'Not found'})

    def do_POST(self) -> None:
        if self.path != '/api/schedule':
            self._send_json(404, {'error': 'Not found'})
            return

        try:
            content_length = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            content_length = 0

        raw_body = self.rfile.read(content_length)
        try:
            payload = json.loads(raw_body.decode('utf-8'))
        except Exception:
            self._send_json(400, {'error': 'Invalid JSON payload'})
            return

        self.runtime.save_schedule(payload)
        self._send_json(200, {'ok': True})

    def log_message(self, format: str, *args: Any) -> None:
        print(f'{self.address_string()} - {format % args}', flush=True)


def main() -> None:
    runtime = ScheduleRuntime()
    ScheduleRequestHandler.runtime = runtime

    scheduler_thread = threading.Thread(target=runtime.tick_forever, daemon=True)
    scheduler_thread.start()

    weather_thread = threading.Thread(target=runtime.weather_forever, daemon=True)
    weather_thread.start()

    server = ThreadingHTTPServer((BIND_HOST, BIND_PORT), ScheduleRequestHandler)
    print(f'Factory alarm server listening on http://{BIND_HOST}:{BIND_PORT}', flush=True)
    server.serve_forever()


if __name__ == '__main__':
    main()