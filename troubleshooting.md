# Troubleshooting

First-response checks and fixes for common Fedora laptop issues.

## Always start here

```bash
# What failed at boot?
systemctl --failed
journalctl -b -p err --no-pager

# Recent kernel complaints (especially hardware)
dmesg --level=err,warn | tail -50

# Which Fedora/kernel am I on?
cat /etc/fedora-release
uname -r

# Is the disk full? (surprisingly common cause of breakage)
df -h /
df -i /
```

Reorder anywhere: run the "always start here" block, then jump to the matching section.

## No network / Wi-Fi dropped

```bash
nmcli device status
nmcli radio wifi
rfkill list
ip -br addr
ip route
resolvectl status
sudo systemctl restart NetworkManager
```
See `networking.md` and the Wi-Fi hardware section in `hardware.md`.

## No sound

```bash
wpctl status
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart wireplumber pipewire pipewire-pulse
alsamixer                              # unmute, raise levels, arrow keys
```
Missing codecs: enable RPM Fusion and install `ffmpeg`, `gstreamer1-plugins-ugly`.

## Bluetooth won't connect

```bash
rfkill list
sudo systemctl restart bluetooth
bluetoothctl
# inside: power on / agent on / default-agent / scan on / pair <MAC> / connect <MAC> / trust <MAC>
```

## Screen brightness or suspend problems

```bash
cat /sys/power/mem_sleep               # s2idle is common on modern laptops
journalctl -b -u systemd-suspend --no-pager
journalctl -b | grep -i 'fail\|error' | tail -50
```

Try forcing deep sleep (persist across reboots):

```bash
echo deep | sudo tee /sys/power/mem_sleep
# persistent: add mem_sleep_default=deep to the kernel command line in GRUB
```

## Runs hot / fan loud / battery drains

```bash
sensors
powerprofilesctl get
top                                    # or htop / btop
powertop
journalctl -b | grep -i thermal
```

## Boot is slow

```bash
systemd-analyze blame
systemd-analyze critical-chain
systemctl list-timers
```
Long-running failing units often show under `systemctl --failed`.

## Disk full

```bash
df -h
sudo du -xh --max-depth=2 / 2>/dev/null | sort -h | tail -20
journalctl --disk-usage
sudo journalctl --vacuum-size=300M
sudo dnf autoremove && sudo dnf clean all
flatpak uninstall --unused
ls -lah /var/tmp /tmp
```

## Package install fails

```bash
sudo dnf clean all
sudo dnf makecache
sudo dnf upgrade --refresh             # repos may have moved forward
sudo dnf distro-sync                   # align packages with the current release
# conflicts? inspect, then allow the swap explicitly
sudo dnf install <pkg> --allowerasing
rpm -Va | grep '^..5'                  # corrupted files
```

## App crashes / won't start

```bash
# run from a terminal to see the real error
<app>
journalctl --user -b | tail -100
coredumpctl list
coredumpctl gdb <PID>
coredumpctl info <PID>
```

## GNOME misbehaving / extensions

```bash
# log out and back in after disabling a suspect extension
gnome-extensions list --enabled
gnome-extensions disable <uuid>
journalctl --user -b -u org.gnome.Shell | tail -50
```

Wayland-specific app issues — try X11 for that app only by logging into an "GNOME on Xorg" session from the login screen.

## Permission denied (even with correct modes)

Check SELinux first:

```bash
ls -Z <file>
sudo ausearch -m avc -ts recent
sudo restorecon -Rv <dir>
```

## Locked out of sudo / broken shell config

```bash
sudo -l                                # what can I actually run
pkexec bash                            # graphical auth prompt path to root
# from a TTY (Ctrl+Alt+F3):
#   log in as root (or a sudo user), fix /etc/sudoers with visudo
visudo                                 # ALWAYS use visudo to edit sudoers
```

## Reset a stuck service or session

```bash
systemctl --user restart <service>
loginctl terminate-user $USER          # nukes your session (saves work first)
sudo reboot
```

## Get help effectively

```bash
# collect a bug report bundle
sudo dnf install sos
sudo sos report --clean

# search the web for the exact error text
# report to Fedora: https://bugzilla.redhat.com
# ask the community: https://ask.fedoraproject.org
```
