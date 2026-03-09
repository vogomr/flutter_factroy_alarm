import schedule
import time
import requests
import json

BASE = "http://<PI-IP>:6680/mopidy/rpc"

def rpc(method, params=None):
    payload = {
        "jsonrpc": "2.0",
        "id": int(time.time()),
        "method": method,
    }
    if params:
        payload["params"] = params
    requests.post(BASE, json=payload, timeout=10)

def play_tone(name):
    rpc("core.tracklist.clear")
    rpc("core.tracklist.add", {"uris": [f"local:track:{name}"]})
    rpc("core.playback.play")

# Example schedules
schedule.every().day.at("12:00").do(lambda: play_tone("lunch_bell.wav"))
schedule.every().day.at("15:00").do(lambda: play_tone("shift_change.wav"))

print("Factory Alarm Scheduler started. Press Ctrl+C to exit.")
while True:
    schedule.run_pending()
    time.sleep(1)
