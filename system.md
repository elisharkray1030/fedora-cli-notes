# System

Services, logs, time, power, and OS upgrades.

## Machine identity and OS version

```bash
hostnamectl                          # hostname, OS, kernel, architecture
cat /etc/fedora-release              # e.g. "Fedora release 44 (Forty Four)"
rpm -E %fedora                       # just the version number, e.g. 44
uname -r                             # running kernel
uname -a                             # full kernel/arch info
cat /etc/os-release                  # portable release metadata
```

Change hostname:

```bash
sudo hostnamectl set-hostname <new-hostname>
```

## systemd services

```bash
systemctl status <service>            # is it running? recent logs?
sudo systemctl start <service>
sudo systemctl stop <service>
sudo systemctl restart <service>
sudo systemctl reload <service>       # re-read config without dropping connections
sudo systemctl enable <service>       # start at boot
sudo systemctl disable <service>
sudo systemctl enable --now <service> # enable and start in one step

systemctl list-units --type=service --state=running   # what's running now
systemctl list-unit-files --state=enabled             # what starts at boot
systemctl --failed                                    # anything broken?
systemctl list-timers                                 # scheduled jobs (cron replacement)

systemctl --user status <user-service>                # per-user services
systemctl --user list-units --type=service
```

Edit a unit (creates an override so package updates don't clobber it):

```bash
sudo systemctl edit <service>         # writes /etc/systemd/system/<service>.d/override.conf
sudo systemctl daemon-reload
```

## Logs (journalctl)

```bash
journalctl -b                         # this boot
journalctl -b -1                      # previous boot
journalctl --list-boots               # list boots with IDs
journalctl -u <service>               # logs for one service
journalctl -f                         # follow live
journalctl -p err -b                  # errors this boot
journalctl --since "10 min ago"
journalctl --since today --until "1 hour ago"
journalctl -u NetworkManager --since "yesterday"
journalctl -k                         # kernel messages (like dmesg)
journalctl -o short-precise           # timestamps with sub-second precision
```

Find what's eating disk in the journal:

```bash
journalctl --disk-usage
sudo journalctl --vacuum-size=500M    # trim to 500 MB
sudo journalctl --vacuum-time=2weeks
```

## Time, locale, keyboard

```bash
timedatectl                           # time, timezone, NTP status
timedatectl list-timezones | grep -i chicago
sudo timedatectl set-timezone America/Chicago

localectl status                      # locale + keyboard layout
localectl list-keymaps | grep -i us
sudo localectl set-keymap us
sudo localectl set-x11-keymap us pc105 intl   # X11 layout with variants
```

## Power and reboot

```bash
systemctl poweroff
systemctl reboot
systemctl suspend
systemctl hibernate                   # needs swap >= RAM

reboot
shutdown -h now                       # power off now
shutdown -r +10 "Rebooting in 10"     # scheduled reboot with a message
shutdown -c                           # cancel a scheduled shutdown
```

## Boot and startup performance

```bash
systemd-analyze                       # total boot time
systemd-analyze blame                 # slowest units
systemd-analyze critical-chain        # the serial path that actually matters
systemd-analyze plot > boot.svg       # visual timeline (open in a browser)
```

## Kernel modules

```bash
lsmod                                 # loaded modules
modinfo <module>                      # details about a module
sudo modprobe <module>                # load now
sudo modprobe -r <module>             # unload
lsmod | grep -i bluetooth
dmesg | tail -50                      # recent kernel messages
```

Blacklist a module persistently:

```bash
echo "blacklist <module>" | sudo tee /etc/modprobe.d/blacklist-<module>.conf
sudo dracut -f                        # rebuild initramfs
```

## Fedora release upgrade

```bash
# 1. Fully update the current release first
sudo dnf upgrade --refresh

# 2. Install the upgrade plugin
sudo dnf install dnf-plugin-system-upgrade

# 3. Download the next release (44 -> 45 in this example)
sudo dnf system-upgrade download --releasever=45

# 4. Reboot into the upgrade
sudo dnf system-upgrade reboot

# 5. After reboot, review what happened
sudo dnf system-upgrade log --number=-1
```

Clean up old kernels / packages afterwards:

```bash
sudo dnf autoremove
```

## Environment and shell

```bash
echo $SHELL                           # which shell am I using
chsh -s /usr/bin/zsh                  # change default shell
env                                   # all environment variables
printenv PATH
which <command>                       # path to a command
type <command>                        # alias/function/binary?
alias                                 # current aliases
```

Make aliases/Env permanent (Bash):

```bash
# ~/.bashrc  (interactive shells)  or  ~/.bash_profile  (login shells)
export EDITOR=nano
alias ll='ls -alF'
alias gs='git status -sb'
```

Reload config without logging out:

```bash
source ~/.bashrc
```
