# post-arch

Mauro's Arch Linux post-install setup: KDE Plasma, development tools, gaming,
media applications, and familiar shell aliases.

## Run

From a terminal in your newly installed Arch system, as your regular user:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codella/post-arch/main/install.sh)
```

No clone or additional runtime needed. Requires working internet, `curl`, a
sudo-capable user, x86_64 Arch, and mkinitcpio. This profile targets Intel CPU / AMD
Radeon hardware. Finish the base Arch installation first. Supported bootloaders:
existing GRUB, or systemd-boot with its boot partition mounted at `/boot`.
Secure Boot signing is not configured by this script.

Preview without changing anything:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codella/post-arch/main/install.sh) --dry-run
```

The command follows `main`; substitute a commit SHA for `main` to pin a reviewed
version. Inspect `install.sh` before running. There is one setup confirmation;
sudo, pacman, makepkg, and paru may also prompt. AUR build scripts run as your user.
The first paru build opens its PKGBUILD in `less` (press `q` to continue).

## Included

- Standard, LTS, and Zen kernels; LTS/Zen headers and documentation.
- Full Plasma desktop, Dolphin, Konsole, Ark, Okular.
- Firefox and Chromium.
- Steam, ProtonUp-Qt, DOSBox Staging.
- VLC with all plugins, OBS Studio, OpenShot.
- micro, vim, VS Code, Git, GitHub CLI, lazygit, mise, paru.
- zsh, Starship, yazi, eza, bat, btop.
- NetworkManager, OpenVPN integration, Bluetooth, printing, Avahi/mDNS.
- PipeWire audio, Intel/AMD firmware and graphics, Steam's 32-bit graphics,
  common fonts, Btrfs tools, zstd zram, and basic download/archive/build tools.

The package arrays at the top of `install.sh` are the editable manifest.
Packages that may move between repositories and the AUR are resolved at runtime.
Dependencies are handled by pacman/paru rather than copied from the old system.
No htop, zellij, nano, or paru-debug is requested. Debug package generation is
disabled for this run's AUR builds; existing packages are never removed.

## Configuration and reruns

The installer enables multilib and performs a full system upgrade. It enables
services for next boot without restarting your current network or desktop.
OpenVPN connections and individual printers still need their own credentials or
device setup. It does not copy secrets, Wi-Fi/VPN profiles, personal files,
firewall rules, or disk mounts from the original machine.

It sets zsh as your login shell, initializes Starship and mise, selects micro as
`EDITOR`, and restores `mi`, `yz`, `ls`, `lg`, and `cat`. It adds one source line to
`.zshrc`, preserving existing content. On an existing customized system, old
initialization lines/aliases remain and may need manual consolidation.

Changed system files and existing shell files get adjacent timestamped `.bak`
copies. Package installation uses `--needed`; reruns do not duplicate the source
line or multilib section. A failed run stops with its build directory retained;
correct the reported problem and rerun. Package upgrades are not rolled back by
configuration backups.

For systemd-boot, dedicated initramfs presets and entries are generated for all
three kernels using the running system's kernel command line, excluding boot
image/initrd paths. Existing entries/defaults stay intact. GRUB's configuration
is regenerated instead. Reboot manually once setup completes.

## Validation

```bash
bash -n install.sh
bash tests/check.sh
bash install.sh --dry-run
```

Tests check configuration transformations and repeatability without installing
packages or changing the host. A complete installation must be tested on a fresh
Arch machine/VM; static checks do not prove successful AUR builds or booting.

References: [Steam](https://wiki.archlinux.org/title/Steam),
[Avahi](https://wiki.archlinux.org/title/Avahi),
[paru](https://github.com/Morganamilo/paru).
