# Packages

Installing, updating, and removing software. Fedora 41+ ships **dnf5**; the `dnf` command maps to it.

## Essentials

```bash
sudo dnf upgrade --refresh            # update everything (refresh metadata first)
sudo dnf install <package>
sudo dnf remove <package>
sudo dnf reinstall <package>
sudo dnf search <term>
sudo dnf info <package>
sudo dnf list installed
sudo dnf list available
```

## Finding out where a file came from / what a package owns

```bash
rpm -q <package>                      # is it installed, and what version
rpm -qa | grep <term>                 # search installed packages
rpm -ql <package>                     # files a package installed
rpm -qf /usr/bin/<command>            # which package owns this file
rpm -qi <package>                     # package metadata
rpm -q --changelog <package> | head   # recent changes
rpm --verify <package>                # are installed files intact?
```

## Searching repos for a file or command

```bash
sudo dnf provides '*/<command>'       # which package ships this binary
sudo dnf repoquery --whatprovides <file>
sudo dnf repoquery --requires <package>
sudo dnf repoquery --whatrequires <package>
```

## History and rollback

```bash
sudo dnf history                      # list transactions
sudo dnf history info <ID>            # what a transaction did
sudo dnf history undo <ID>            # reverse a transaction
sudo dnf history rollback <ID>        # roll back everything after <ID>
```

## Groups, environments, and modules

```bash
sudo dnf group list
sudo dnf group info "Development Tools"
sudo dnf group install "Development Tools"
sudo dnf group remove "Development Tools"
```

## Cleaning up

```bash
sudo dnf autoremove                   # remove orphaned dependencies
sudo dnf clean all                    # clear cached metadata/packages
sudo dnf makecache                    # rebuild metadata cache
dnf repo list                         # enabled repositories
sudo dnf config-manager setopt <repo>.enabled=0   # disable a repo
```

## RPM files and local installs

```bash
sudo dnf install ./<package>.rpm      # preferred: resolves dependencies
sudo rpm -ivh <package>.rpm           # raw rpm, no dependency resolution
sudo rpm -e <package>                 # erase
```

## RPM Fusion (free + nonfree repos)

```bash
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf upgrade --refresh
```

Then you can install things like hardware codecs:

```bash
sudo dnf install ffmpeg gstreamer1-plugins-ugly
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

## COPR repositories

```bash
sudo dnf copr enable <user>/<project>
sudo dnf copr list
sudo dnf copr remove <user>/<project>
```

## Flatpak (most desktop apps)

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub <app-id>
flatpak search <term>
flatpak list
flatpak list --app                   # apps only
flatpak update
flatpak uninstall <app-id>
flatpak uninstall --unused           # remove unused runtimes
flatpak run <app-id>
flatpak info <app-id>
```

Grant an app access to your home dir:

```bash
flatpak override --user --filesystem=home <app-id>
flatpak permissions                  # inspect overrides
```

Install a specific `.flatpakref` or `.flatpak` bundle:

```bash
flatpak install ./<app>.flatpakref
flatpak install ./<app>.flatpak
```

## Toolbox / Distrobox (throwaway dev containers)

```bash
toolbox create                       # container matching your host release
toolbox create --distro fedora --release 44
toolbox list
toolbox enter
toolbox run --container <name> <command>
toolbox rm <name>
```

```bash
distrobox create --name dev --image fedora:latest
distrobox enter dev
distrobox list
distrobox rm dev
```

## Version pinning and downgrades

```bash
sudo dnf install <package>-<version>          # exact version
sudo dnf downgrade <package>
dnf list --showduplicates <package>
sudo dnf versionlock add <package>            # requires python3-dnf-plugin-versionlock
sudo dnf versionlock list
```

## Handy one-liners

```bash
# size of installed packages, biggest first
rpm -qa --qf '%{SIZE}\t%{NAME}\n' | sort -rn | head -20

# count installed packages
rpm -qa | wc -l

# which apps auto-start in GNOME
gnome-session-properties 2>/dev/null || ls ~/.config/autostart
```
