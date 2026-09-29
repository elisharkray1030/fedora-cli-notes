# Security

SELinux, GPG, SSH keys, secrets, and quick audits.

## SELinux (Fedora enforces this by default)

```bash
getenforce                            # Enforcing / Permissive / Disabled
sestatus                              # detailed status
sestatus -b | grep -v disabled        # all booleans
sudo setenforce 0                     # Permissive until reboot (debugging only)
sudo setenforce 1                     # back to Enforcing
```

Don't just disable SELinux — diagnose it:

```bash
sudo ausearch -m avc -ts recent       # recent denials
sudo ausearch -m avc -ts today | audit2why
sudo journalctl -t setroubleshoot --since today
sudo sealert -a /var/log/audit/audit.log   # setroubleshoot-server
```

Relabel files after moving them (common cause of denials):

```bash
sudo restorecon -Rv /path/to/dir
ls -Z <file>                          # show SELinux context
```

Custom contexts with semanage:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
sudo restorecon -Rv /var/www/html
sudo semanage fcontext -l | grep httpd
sudo semanage port -a -t http_port_t -p tcp 8080
```

Booleans (toggle features without recompiling policy):

```bash
getsebool -a | grep httpd
sudo setsebool -P httpd_can_network_connect on   # -P = persistent
```

## File permissions and setuid audit

```bash
find / -perm -4000 -type f 2>/dev/null          # setuid binaries
find / -perm -o+w -type f 2>/dev/null           # world-writable files
sudo rpm -Va 2>/dev/null | grep '^..5'          # files whose checksum changed
sudo ls -l /etc/sudoers.d/                      # who can sudo
sudo -l                                         # what may I run as root
```

## SSH keys

```bash
ssh-keygen -t ed25519 -a 100 -C "laptop"        # modern, with KDF rounds
ssh-keygen -t ed25519 -f ~/.ssh/id_work -C "work"
ssh-keygen -l -f ~/.ssh/id_ed25519.pub          # fingerprint
ssh-keygen -p -f ~/.ssh/id_ed25519              # change passphrase
ssh -i ~/.ssh/id_work <host>
```

Hardening `~/.ssh/config`:

```
Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
```

Start the agent and add keys:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add -l
```

## GPG

```bash
gpg --full-generate-key                         # create a key
gpg --list-secret-keys --keyid-format=long
gpg --list-keys
gpg --export -a <key-id> > public.key           # share public key
gpg --import other-public.key
gpg --edit-key <key-id>                          # interactive: sign, add UID, expire
gpg --encrypt --recipient <key-id> file
gpg --decrypt file.gpg
gpg --sign --armor file
gpg --verify file.asc
gpg --detach-sign --armor file
gpg --send-keys --keyserver keyserver.ubuntu.com <key-id>
```

Sign git commits:

```bash
gpg --list-secret-keys --keyid-format=long | grep sec
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true
```

## Secrets in the login keyring (GNOME)

```bash
secret-tool store --label="Wi-Fi" service wifi ssid "<SSID>"   # prompts for value
secret-tool lookup service wifi ssid "<SSID>"
secret-tool clear service wifi ssid "<SSID>"
```

For CLI password managers:

```bash
sudo dnf install pass
pass init "<gpg-key-id>"
pass generate site/example 20
pass show site/example
pass insert -m notes/example
```

## Passwords and random data

```bash
openssl rand -base64 24                 # random password
head -c 32 /dev/urandom | base64
pwgen -s 20 1                           # pwgen package
```

## Encrypted archives

```bash
# symmetric, with headers authenticated
age -p -o secret.age secret.txt         # age package
age -d secret.age

# tar + gpg
tar czf - <dir> | gpg -c --output backup.tar.gz.gpg
gpg -d backup.tar.gz.gpg | tar xzf -
```

## Firewall and open ports (see networking.md too)

```bash
sudo ss -tulpn                          # what is listening
sudo firewall-cmd --list-all
sudo nmap -sT -p- 127.0.0.1             # local port scan
```

## Misc audits

```bash
last -n 20                              # recent logins
lastb -n 20                             # failed logins (needs root)
who
w
sudo journalctl -u sshd --since today
sudo dnf install lynis && sudo lynis audit system   # thorough audit
```
