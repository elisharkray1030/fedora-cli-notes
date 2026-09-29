#!/bin/bash
# Run the refresh-rate switch once at start, then on every UPower power-source change.
# Runs inside a systemd --user service, so the session bus is available.
#
# Install: copy this and auto-refresh-rate.sh to ~/.local/bin/, chmod +x both,
# then copy switch-refresh-rate.service to ~/.config/systemd/user/ and:
#   systemctl --user daemon-reload
#   systemctl --user enable --now switch-refresh-rate.service
#   sudo rm -f /etc/udev/rules.d/99-refresh-rate-switch.rules
"$HOME/.local/bin/auto-refresh-rate.sh"

gdbus monitor --system --dest org.freedesktop.UPower \
    --object-path /org/freedesktop/UPower \
| grep --line-buffered 'OnBattery' \
| while read -r _; do
    "$HOME/.local/bin/auto-refresh-rate.sh"
done
