# Networking

Fedora Workstation uses **NetworkManager**, controlled from the CLI with `nmcli`.

## Connection overview

```bash
nmcli general status                   # overall networking state
nmcli device status                    # each device + its state
nmcli connection show                  # saved connections
nmcli connection show --active         # currently active
nmcli connection show <name>           # all settings for one connection
```

## Wi-Fi

```bash
nmcli radio wifi                        # on/off
nmcli radio wifi off
nmcli radio wifi on

nmcli device wifi list                  # scan and list networks
nmcli device wifi rescan                # force a fresh scan
nmcli device wifi list --rescan yes     # scan then list

nmcli device wifi connect "<SSID>" password "<password>"
nmcli device wifi connect "<SSID>" password "<password>" hidden yes
nmcli device wifi hotspot ssid MyHotspot password <8+chars>
```

Manage saved Wi-Fi:

```bash
nmcli connection modify "<SSID>" connection.autoconnect yes
nmcli connection up "<SSID>"
nmcli connection down "<SSID>"
nmcli connection delete "<SSID>"
nmcli connection modify "<SSID>" ipv4.method auto
```

## Wired and general connections

```bash
nmcli device connect <iface>
nmcli device disconnect <iface>

# static IPv4 on an existing connection
sudo nmcli connection modify "<name>" ipv4.method manual \
  ipv4.addresses 192.168.1.50/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "1.1.1.1 9.9.9.9"
```

## Low-level: ip, ss, ping, DNS

```bash
ip addr show                           # interfaces and addresses
ip -br addr                            # brief, one line per interface
ip route                               # routing table
ip route get 1.1.1.1                   # which route/interface a host uses
ip link set <iface> up

ss -tulpn                              # listening TCP/UDP sockets + process
ss -tulp                               # no name resolution (faster)
ss -tan                                # established TCP connections
netstat isn't needed — use ss

ping -c4 1.1.1.1                       # is the network up at all
ping -c4 fedoraproject.org             # is DNS + routing working

resolvectl status                      # DNS servers per interface (systemd-resolved)
resolvectl query fedoraproject.org
dig +short fedoraproject.org           # requires bind-utils
nslookup fedoraproject.org
```

## Downloading and HTTP

```bash
curl -O https://example.com/file       # save with remote filename
curl -L -o out.zip https://example.com/file   # follow redirects
curl -I https://example.com            # headers only
curl -s https://api.example.com | jq   # pipe JSON to jq
wget -c https://example.com/big.iso    # resumable download
wget --mirror --convert-links https://example.com
```

## SSH

```bash
ssh <user>@<host>
ssh -p 2222 <user>@<host>
ssh -i ~/.ssh/<key> <user>@<host>
ssh -v <user>@<host>                   # verbose, for debugging auth
ssh <host> '<command>'                 # run one remote command

# generate a modern key
ssh-keygen -t ed25519 -C "laptop"
ssh-copy-id <user>@<host>              # install your public key
```

`~/.ssh/config` for shortcuts:

```
Host myserver
    HostName 203.0.113.10
    User elijah
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
```

Then just: `ssh myserver`

Tunnels and file transfer:

```bash
ssh -L 8080:localhost:80 <host>        # local forward: localhost:8080 -> host:80
ssh -R 9000:localhost:3000 <host>      # remote forward
scp <file> <user>@<host>:/path/
scp -r <dir> <user>@<host>:/path/
rsync -avh -e ssh <dir>/ <user>@<host>:/path/
sshfs <user>@<host>:/remote /mnt/point   # mount remote over SSH
```

## Firewall (firewalld)

```bash
sudo firewall-cmd --state
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all                      # rules for default zone
sudo firewall-cmd --zone=public --list-all

sudo firewall-cmd --add-service=https             # temporary (until reload/reboot)
sudo firewall-cmd --permanent --add-service=https # persistent
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --remove-service=<service>
sudo firewall-cmd --reload                        # apply permanent changes
sudo firewall-cmd --runtime-to-permanent          # promote current runtime rules
```

Find a service name by port:

```bash
grep -w 80 /usr/lib/firewalld/services/*.xml | head
```

## VPN

```bash
nmcli connection show | grep -i vpn
nmcli connection up "<vpn-name>"
nmcli connection down "<vpn-name>"
nmcli connection import type openvpn file <profile>.ovpn
```

WireGuard (if installed):

```bash
sudo wg show
sudo wg-quick up <iface>
sudo wg-quick down <iface>
```

## Bluetooth tethering / USB tethering

```bash
nmcli device status                    # look for a phone/usb interface
nmcli device connect <iface>
```

## Troubleshooting quick pass

```bash
nmcli device status                    # is the device managed/connected?
nmcli connection show --active
ip -br addr
ip route
resolvectl status
ping -c2 1.1.1.1                       # link + IP works?
ping -c2 fedoraproject.org             # DNS works?
sudo systemctl restart NetworkManager  # last resort
journalctl -u NetworkManager --since "10 min ago"
```
