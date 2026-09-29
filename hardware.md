# Hardware (laptop)

Battery, screen, Bluetooth, touchpad, Wi-Fi hardware, and thermals.

## Identify the hardware

```bash
lscpu                                  # CPU model, cores, flags
free -h                                # RAM and swap usage
lspci                                  # PCI devices (GPU, Wi-Fi, audio)
lspci -nnk                             # + kernel driver in use (key for Wi-Fi/GPU issues)
lsusb                                  # USB devices
sudo dmidecode -t system -t battery    # model, BIOS, battery design capacity
lsblk                                  # block devices (see storage.md)
sudo lshw -short                       # summarized hardware tree
```

## Battery

```bash
upower -i $(upower -e | grep -i 'BAT')     # charge, health, time remaining, cycles
cat /sys/class/power_supply/BAT0/capacity  # percent
cat /sys/class/power_supply/BAT0/status    # Charging/Discharging/Full
cat /sys/class/power_supply/BAT0/cycle_count 2>/dev/null
upower -d                              # everything upower knows
```

Energy/charge design vs. current tells you battery wear:

```bash
upower -i $(upower -e | grep -i BAT) | grep -E 'energy-full|energy-full-design|capacity'
```

## Power profiles and thermals

Fedora's default is `power-profiles-daemon`:

```bash
powerprofilesctl                       # current profile and options
powerprofilesctl list
powerprofilesctl set performance       # or balanced / power-saver
powerprofilesctl get
```

If you prefer `tuned` instead:

```bash
sudo dnf install tuned tuned-ppd
sudo systemctl enable --now tuned
tuned-adm list
tuned-adm active
tuned-adm profile balanced
```

Temperatures and sensors:

```bash
sudo dnf install lm_sensors
sudo sensors-detect                    # answer defaults
sensors                                # CPU/GPU temps and fan speeds
watch -n2 sensors                      # live
cat /sys/class/thermal/thermal_zone*/temp
```

Find what is draining battery:

```bash
powertop                               # requires powertop package
sudo powertop --calibrate              # generates a report
```

## Screen brightness

```bash
brightnessctl                          # requires brightnessctl
brightnessctl get
brightnessctl set 50%
brightnessctl set +10%
brightnessctl -l                       # list controllable devices
cat /sys/class/backlight/*/max_brightness
```

## Touchpad

GNOME / Wayland settings:

```bash
gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.3
```

Inspect input devices:

```bash
libinput list-devices                  # requires libinput-utils
xinput list                            # X11 only
```

## Bluetooth

```bash
systemctl status bluetooth
sudo systemctl enable --now bluetooth
rfkill list                            # is it blocked by hardware/software?
rfkill unblock bluetooth

bluetoothctl                           # interactive prompt
```

Inside `bluetoothctl`:

```
power on
agent on
default-agent
scan on
pair <MAC>
connect <MAC>
trust <MAC>
devices
remove <MAC>
quit
```

One-liners without the interactive prompt:

```bash
bluetoothctl show
bluetoothctl devices
bluetoothctl connect <MAC>
bluetoothctl disconnect <MAC>
```

## Wi-Fi hardware

```bash
lspci -nnk | grep -A3 -i network      # chipset + driver
nmcli device show <iface>
iw dev                                 # requires iw; wireless interfaces
iw dev <iface> link                    # signal strength, bitrate
nmcli device wifi list                 # signal per network
sudo dnf install linux-firmware        # ensure firmware is current
```

If Wi-Fi is missing after suspend:

```bash
sudo modprobe -r <module> && sudo modprobe <module>
rfkill list && rfkill unblock all
```

## Audio

```bash
wpctl status                           # PipeWire/WirePlumber status
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5
pactl list short sinks                 # PulseAudio-compatible view
pactl set-default-sink <name>
alsamixer                              # low-level mixer
```

## Webcam and microphones

```bash
ls /dev/video*                         # webcams
v4l2-ctl --list-devices                # requires v4l-utils
arecord -l                             # capture devices
arecord -f cd test.wav                 # quick mic test (Ctrl+C to stop)
```

## Function keys and suspend

```bash
sudo dnf install acpi acpid
acpi_listen                            # see Fn-key events live
sudo systemctl status acpid
```

Suspend/hibernate diagnostics:

```bash
systemctl suspend
journalctl -b -u systemd-suspend --no-pager
cat /sys/power/mem_sleep               # s2idle vs deep
```

## Firmware updates (UEFI/BIOS via LVFS)

```bash
sudo dnf install fwupd
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
sudo fwupdmgr update
```

## Disk health (SMART)

```bash
sudo dnf install smartmontools
sudo smartctl -a /dev/nvme0n1
sudo smartctl -t short /dev/nvme0n1    # start a short self-test
sudo smartctl -l selftest /dev/nvme0n1 # view results
```
