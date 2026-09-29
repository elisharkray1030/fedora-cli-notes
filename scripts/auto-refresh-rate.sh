#!/bin/bash
# Set the eDP-1 refresh rate based on AC/battery, via GNOME's display config.
# Called by watch-power.sh (a systemd --user service).
#
# Adjust the monitor name and mode strings for your machine. Find them with:
#   gnome-monitor-config get -L -M
set -u

online=0
for f in /sys/class/power_supply/AD*/online /sys/class/power_supply/AC*/online; do
    [ -r "$f" ] && [ "$(cat "$f")" = 1 ] && online=1
done

if [ "$online" = 1 ]; then
    gnome-monitor-config set -L -p -M eDP-1 -m 2048x1280@120.001
else
    gnome-monitor-config set -L -p -M eDP-1 -m 2048x1280@60.001
fi
