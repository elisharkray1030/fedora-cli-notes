# Storage

Disks, partitions, mounts, encryption, and Fedora's default Btrfs filesystem.

## Inspect devices

```bash
lsblk                                  # block devices as a tree
lsblk -f                               # + filesystem type, UUID, mountpoint
lsblk -o NAME,FSTYPE,SIZE,LABEL,MOUNTPOINT,UUID
sudo blkid                             # UUIDs and filesystem types
sudo fdisk -l                          # partition tables
df -h                                  # mounted filesystems and free space
df -hT                                 # + filesystem types
findmnt                                # mounted filesystems as a tree
```

## Mounting and unmounting

```bash
lsusb && dmesg | tail -20              # what just got plugged in
sudo mount /dev/sdb1 /mnt
sudo mount -t exfat /dev/sdb1 /mnt     # specify filesystem type
sudo umount /mnt
sudo umount -l /mnt                    # lazy unmount (busy device)
mount | grep <device>
lsof +D /mnt                           # what is holding the mount busy
```

Mount automatically at boot via `/etc/fstab`. Get the UUID first:

```bash
UUID=$(blkid -s UUID -o value /dev/sdb1)

# <file system>                            <mount point>  <type>  <options>        <dump> <pass>
# UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /mnt/data     ext4    defaults,nofail   0      2
```

Test fstab without rebooting:

```bash
sudo mount -a                          # mount everything in fstab
sudo findmnt --verify                  # validate fstab
```

Mount a `.iso`:

```bash
sudo mkdir -p /mnt/iso
sudo mount -o loop file.iso /mnt/iso
sudo umount /mnt/iso
```

## Formatting and partitioning

```bash
sudo dnf install gparted               # GUI option if you prefer

# Create a filesystem ON A PARTITION (this destroys data)
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.exfat /dev/sdb1              # cross-platform USB drives
sudo mkfs.vfat /dev/sdb1

# Interactive partitioning (needs care)
sudo fdisk /dev/sdb
sudo parted /dev/sdb
sudo gdisk /dev/sdb                    # GPT
```

Check/repair a filesystem (unmount first):

```bash
sudo fsck /dev/sdb1
sudo fsck.ext4 -f /dev/sdb1
sudo e2fsck -p /dev/sdb1
sudo ntfsfix /dev/sdb1                 # ntfs-3g package
```

## Disk usage and cleanup

```bash
du -sh <dir>
ncdu                                   # interactive
df -i                                  # inode usage (many small files)
sudo du -xh --max-depth=2 / 2>/dev/null | sort -h | tail -20
sudo dnf clean all
journalctl --disk-usage
flatpak uninstall --unused
```

Trash and caches:

```bash
du -sh ~/.cache ~/.local/share/Trash
rm -rf ~/.cache/thumbnails/*
```

## LUKS full-disk / partition encryption

```bash
sudo cryptsetup luksDump /dev/nvme0n1p3
sudo cryptsetup luksOpen /dev/nvme0n1p3 mycrypt
sudo cryptsetup luksClose mycrypt
sudo cryptsetup status mycrypt
```

Header backup (do this before you need it):

```bash
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p3 \
  --header-backup-file ~/luks-header-backup.img
```

Add a keyfile or extra passphrase:

```bash
sudo cryptsetup luksAddKey /dev/nvme0n1p3
sudo cryptsetup luksRemoveKey /dev/nvme0n1p3
```

## LVM

```bash
sudo pvs                               # physical volumes
sudo vgs                               # volume groups
sudo lvs                               # logical volumes
sudo lvdisplay
sudo pvcreate /dev/sdb1
sudo vgextend <vg> /dev/sdb1
sudo lvextend -l +100%FREE /dev/<vg>/<lv>
sudo resize2fs /dev/<vg>/<lv>          # ext4
sudo xfs_growfs /mountpoint            # xfs
```

## Btrfs (Fedora default)

```bash
sudo btrfs filesystem usage /          # space, including raid overhead
sudo btrfs filesystem df /             # usage per data type
sudo btrfs subvolume list /            # subvolumes (root, home, etc.)
sudo btrfs subvolume show /
sudo btrfs scrub start /               # verify checksums in the background
sudo btrfs scrub status /
sudo btrfs balance start -dusage=50 /  # reclaim unallocated chunks
sudo btrfs device stats /              # I/O errors per device
```

Snapshots (Fedora doesn't snapshot `/` by default; this is manual):

```bash
sudo btrfs subvolume snapshot -r / /snapshots/root-$(date +%F)
sudo btrfs subvolume list / | grep snapshots
```

Compression and mount options live in `/etc/fstab`, e.g. `compress=zstd:1`.

## Snapshot automation (snapper)

Fedora doesn't snapshot `/` by default. `snapper` (with the `btrfs-assistant` GUI) adds
scheduled snapshots and cleanup. On a default Fedora Btrfs layout, `/` is the subvolume
`root` and `/home` is `home`, so use one config per subvolume you want to protect.

```bash
sudo dnf install snapper btrfs-assistant

# Create a config per subvolume
sudo snapper -c root create-config /
sudo snapper -c home create-config /home

# create-config creates the timers but does NOT start them — start them now
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
systemctl list-timers 'snapper*'

# Baseline snapshot
sudo snapper -c root create --description "baseline after setup"
sudo snapper -c home create --description "baseline after setup"

# List without opening a pager
sudo snapper -c root list | cat
```

Common operations:

```bash
sudo snapper -c root list                     # all snapshots
sudo snapper -c root status <N>..<M>          # what changed between two snapshots
sudo snapper -c root undochange <N>..<M>      # roll those changes back
sudo snapper -c root delete <N>               # remove one snapshot
sudo snapper -c root get-config               # limits / timeline settings (TIMELINE_LIMIT_*)
```

**Habit — snapshot before upgrades:**

```bash
sudo snapper -c root create --description "pre-upgrade $(date +%F)"
sudo dnf upgrade --refresh
```

Notes:
- Snapshots are **copy-on-write**, so they're cheap, but old ones still pin changed blocks.
  `snapper-cleanup.timer` prunes them; tune the `TIMELINE_LIMIT_*` values via `get-config`.
- These are for **file recovery**, not "boot into a snapshot". Booting a snapshot needs
  `grub-btrfs`, which is not in Fedora's official repos.
- `/boot` is a separate ext4 filesystem, so `/` snapshots don't include kernels/initramfs.

Keep an eye on pinned space:

```bash
sudo snapper -c root list | cat
sudo btrfs filesystem usage /
journalctl -u snapper-timeline --no-pager | tail     # confirm the timeline ran
```

## Maintenance timers

```bash
systemctl list-timers fstrim.timer            # weekly TRIM; enabled on Fedora by default
sudo systemctl enable --now fstrim.timer
sudo btrfs scrub start / && sudo btrfs scrub status /   # periodic checksum verification
```

## Swap

```bash
swapon --show
free -h
cat /proc/swaps
sudo mkswap /dev/<swap-partition>
sudo swapon /dev/<swap-partition>
# zram (Fedora default for Workstation) is managed by zram-generator
zramctl
```

## USB / removable media

```bash
udisksctl status
udisksctl mount -b /dev/sdb1           # user-level mount, no sudo
udisksctl unmount -b /dev/sdb1
lsblk -o NAME,SIZE,LABEL,MOUNTPOINT
```

Write an ISO to a USB stick:

```bash
sudo dnf install mediawriter            # graphical Fedora Media Writer
lsblk                                   # confirm the target device — get this right!
sudo dd if=fedora.iso of=/dev/sdX bs=8M status=progress oflag=sync
sudo sync
```
