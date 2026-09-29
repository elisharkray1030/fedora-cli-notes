# Graphics (Intel + NVIDIA hybrid)

What to run when a laptop has both an Intel iGPU and an NVIDIA dGPU.

## Identify what you have

```bash
lspci -nnk | grep -iA3 'vga\|3d'        # GPUs + the kernel driver in use
lsmod | grep -E 'nvidia|nouveau|i915|xe'
ls /usr/lib/modules/$(uname -r)/extra   # out-of-tree (akmod) modules, e.g. nvidia
glxinfo | grep -E 'OpenGL renderer|OpenGL vendor'   # mesa-demos
```

## envycontrol — choose which GPU is active

```bash
sudo dnf install envycontrol

envycontrol --query             # integrated | hybrid | nvidia
sudo envycontrol -s integrated  # iGPU only; dGPU fully powered off (best battery)
sudo envycontrol -s hybrid      # both; dGPU on demand (best balance)
sudo envycontrol -s nvidia      # dGPU drives everything (best performance)
# log out/in (or reboot) for a mode change to take effect
```

| Mode | What it does | `nvidia-smi` |
| --- | --- | --- |
| `integrated` | Blacklists the `nvidia*` modules and udev-removes the dGPU from PCI | fails — expected |
| `hybrid` | nvidia modules load; render on demand with `prime-run` | works |
| `nvidia` | dGPU is the primary display GPU | works |

### Footgun: a static NVIDIA blacklist

With `integrated`, EnvyControl writes `/etc/modprobe.d/blacklist-nvidia.conf` and
`/etc/udev/rules.d/50-remove-nvidia.rules`. A *static* blacklist of every `nvidia*` module
will silently stop `envycontrol -s hybrid` from bringing the dGPU back. If a mode switch
"does nothing", look here first:

```bash
grep -rn nvidia /etc/modprobe.d/
cat /etc/udev/rules.d/50-remove-nvidia.rules 2>/dev/null
```

## Run a single app on the dGPU (hybrid mode)

```bash
prime-run <app>                      # helper from envycontrol/nvidia-prime
# or explicitly:
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>
```

On Wayland, per-app GPU selection is limited — the compositor/app decides. `prime-run`
matters mostly for X11 and XWayland.

## Force the iGPU / a specific Mesa driver

```bash
DRI_PRIME=0 <app>                       # pick the iGPU when both are present
MESA_LOADER_DRIVER_OVERRIDE=iris <app>  # force the classic Intel 'iris' driver
```

- On Meteor Lake and newer, Fedora is moving to the `xe` driver; forcing `iris` overrides
  that. Prefer a **per-app** variable over putting it in `~/.bashrc`.
- `GS_BACKEND=gl` forces GL compositing in GTK/GNOME apps — a debugging workaround, not a
  default.

## Verify the dGPU is really off (or on)

```bash
nvidia-smi                                    # fails on integrated — expected, not a bug
lspci | grep -i nvidia                        # the card is still listed; only the driver is detached
lsmod | grep nvidia
cat /sys/bus/pci/drivers/nvidia/*/power/control   # 'auto' = runtime power management
```

## Firmware / module refresh

```bash
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda   # if you need CUDA
sudo akmods --force && sudo dracut -f                    # rebuild after kernel updates
```

Power-management knobs for hybrid laptops live in `/etc/modprobe.d/nvidia-pm.conf`:

```
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_PreserveVideoMemoryAllocations=1
```

## When something looks wrong

```bash
journalctl -b -k | grep -iE 'nvidia|drm|i915|xe'
dmesg | grep -iE 'nvidia|nouveau'
journalctl -u nvidia-suspend -u nvidia-resume --no-pager
flatpak override --user --device=dri <app-id>     # let a Flatpak use the GPU
```
