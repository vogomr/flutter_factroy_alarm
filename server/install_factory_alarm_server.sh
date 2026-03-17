#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${FACTORY_ALARM_APP_DIR:-/opt/factory_alarm}"
STATE_DIR="${FACTORY_ALARM_STATE_DIR:-/var/lib/factory_alarm}"
SERVICE_USER="${FACTORY_ALARM_SERVICE_USER:-admin01}"
SERVICE_NAME="factory-alarm-server.service"

sudo install -d -m 0755 "$APP_DIR"
sudo install -d -m 0755 -o "$SERVICE_USER" -g "$SERVICE_USER" "$STATE_DIR"
sudo install -m 0755 "$SCRIPT_DIR/factory_alarm_server.py" "$APP_DIR/factory_alarm_server.py"
sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$STATE_DIR"
sed "s/__SERVICE_USER__/${SERVICE_USER}/g" "$SCRIPT_DIR/factory-alarm-server.service" | sudo tee "/etc/systemd/system/${SERVICE_NAME}" > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"
sudo systemctl status "$SERVICE_NAME" --no-pager