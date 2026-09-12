# post-arch

Arch Linux post-install setup for KDE Plasma, development, gaming, and media.

## Usage

Run from a terminal as a regular user with sudo access:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codella/post-arch/main/install.sh)
```

Add `--dry-run` to preview without making changes. Review `install.sh` before
running; package installation and AUR builds may prompt for confirmation.

Requires an installed x86_64 Arch system, internet access, curl, and mkinitcpio.
Targets Intel CPUs and AMD Radeon graphics. Supports existing GRUB installations
or systemd-boot with the boot partition mounted at `/boot`. Secure Boot signing
is not configured.

## Included

- KDE Plasma, Firefox, and Chromium.
- Standard, LTS, and Zen kernels, with LTS/Zen headers and documentation.
- Development tools, editors, paru, and zsh with Starship and aliases.
- Steam, ProtonUp-Qt, DOSBox Staging, VLC, OBS Studio, and OpenShot.
- Networking, Bluetooth, printing, audio, graphics drivers, fonts, and zram.

Edit the package arrays in `install.sh` to customize the selection.

The installer upgrades the system, configures services and boot entries, and
backs up changed configuration files. Existing packages are not removed.
Reboot manually after completion. Printers and VPN connections may need further
setup.

## Checks

```bash
bash -n install.sh
bash tests/check.sh
```

Automated checks cover syntax and configuration logic. A full installation on a
fresh Arch system has not yet been verified.
