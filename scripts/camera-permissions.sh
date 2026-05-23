#!/bin/bash
set -e
echo 'SUBSYSTEM=="video4linux", GROUP="video", MODE="0666"' | sudo tee /etc/udev/rules.d/99-zeye-usb-camera.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG video $USER
echo "Camera permissions updated."
