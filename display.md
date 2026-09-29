# Display & Refresh Rate

Monitors, resolution, refresh rate, and scaling — mostly GNOME on Wayland.

## Query the current layout

```bash
gnome-monitor-config get -L          # logical monitors
gnome-monitor-config get -L -M       # + supported modes per monitor
xrandr                               # X11 only
wlr-randr                            # wlroots compositors (Sway)
cat ~/.config/monitors.xml           # GNOME's saved layout
```

## Change resolution / refresh / scale

`gnome-monitor-config` edits GNOME's display state directly — use the **exact** mode string
from `get -M` (e.g. `2048x1280@120.001`, not `@120`):

```bash
gnome-monitor-config set -L -p -M eDP-1 -m 2048x1280@120.001   # primary @ 120 Hz
gnome-monitor-config set -L -p -M eDP-1 -m 2048x1280@60.001    # @ 60 Hz
gnome-monitor-config set -L -M eDP-1 -s 2                      # 2x scale
gnome-monitor-config reset                                     # back to defaults
```

Text scaling (GNOME):

```bash
gsettings get org.gnome.desktop.interface text-scaling-factor
gsettings set org.gnome.desktop.interface text-scaling-factor 1.25
```

## Auto-switch refresh rate on AC vs battery

Goal: 120 Hz on AC, 60 Hz on battery.

### The wrong way (and why it fails)

The obvious udev rule looks fine but **does not work**:

```
# /etc/udev/rules.d/99-refresh-rate-switch.rules
SUBSYSTEM=="power_supply", ACTION=="change", RUN+="/usr/bin/systemctl --user -M youruser@ start switch-refresh-rate.service"
```

udev runs without your session bus / runtime directory, so `systemctl --user -M <user>@`
fails every time:

```
Failed to connect to system scope bus via machine transport: Permission denied
Failed to start switch-refresh-rate.service: Transport endpoint is not connected
```

The udev worker logs the failure and the display never switches.

### The right way: a user service watching UPower over D-Bus

A `systemd --user` service **does** have the session bus, and UPower already tracks whether
you're on battery.

> **Ready-to-use copies** of the three files below live in
> [`scripts/`](scripts/) — `auto-refresh-rate.sh`, `watch-power.sh`, and
> `switch-refresh-rate.service`. Install notes are in the script headers.

`~/.local/bin/auto-refresh-rate.sh`:

```bash
#!/bin/bash
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
```

`~/.local/bin/watch-power.sh`:

```bash
#!/bin/bash
# run once at start, then on every UPower change
"$HOME/.local/bin/auto-refresh-rate.sh"
gdbus monitor --system --dest org.freedesktop.UPower \
    --object-path /org/freedesktop/UPower \
| grep --line-buffered 'OnBattery' \
| while read -r _; do "$HOME/.local/bin/auto-refresh-rate.sh"; done
```

`~/.config/systemd/user/switch-refresh-rate.service`:

```ini
[Unit]
Description=Switch refresh rate on power source change
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/watch-power.sh
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

Enable it and remove the udev rule:

```bash
chmod +x ~/.local/bin/auto-refresh-rate.sh ~/.local/bin/watch-power.sh
systemctl --user daemon-reload
systemctl --user enable --now switch-refresh-rate.service
sudo rm -f /etc/udev/rules.d/99-refresh-rate-switch.rules
```

Verify:

```bash
systemctl --user status switch-refresh-rate.service
journalctl --user -u switch-refresh-rate.service -f
```

### Why 2 and not 1

If you also tune Homebrew or check PATH counts: `brew shellenv` prepends **both** `bin` and
`sbin`, so two PATH entries is correct for a single evaluation; four means it ran twice.
