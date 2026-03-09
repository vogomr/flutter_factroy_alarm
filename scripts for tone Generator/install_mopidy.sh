#!/bin/bash
set -e

echo "Updating system..."
sudo apt update
sudo apt upgrade -y

echo "Installing Mopidy..."
sudo apt install -y mopidy mopidy-local mopidy-alsamixer python3-pip

echo "Installing Mopidy-Iris..."
sudo pip3 install Mopidy-Iris

echo "Creating media directory..."
sudo mkdir -p /var/lib/mopidy/media
sudo chown -R mopidy:mopidy /var/lib/mopidy/media

echo "Creating config file..."
sudo tee /etc/mopidy/mopidy.conf > /dev/null << 'EOF'
[http]
enabled = true
hostname = 0.0.0.0
port = 6680

[local]
enabled = true
media_dir = /var/lib/mopidy/media
scan_on_start = true

[audio]
mixer = software
output = alsasink

[iris]
enabled = true
EOF

echo "Enabling mopidy service..."
sudo systemctl enable mopidy
sudo systemctl restart mopidy

echo "Installation complete!"
echo "Open http://<PI-IP>:6680/iris to use the web UI."
