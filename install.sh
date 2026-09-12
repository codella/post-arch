#!/usr/bin/env bash
# Personal Arch desktop bootstrap. Run as your regular user, not with sudo.
set -Eeuo pipefail

packages=(
  base base-devel sudo git curl wget unzip zip less
  linux linux-lts linux-zen linux-lts-headers linux-zen-headers
  linux-lts-docs linux-zen-docs linux-firmware intel-ucode sof-firmware btrfs-progs
  mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon
  plasma-meta dolphin konsole ark okular xdg-utils
  networkmanager networkmanager-openvpn bluez bluez-utils
  cups cups-pk-helper system-config-printer avahi nss-mdns
  pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire wireplumber
  noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation
  zram-generator steam vlc vlc-plugins-all obs-studio
  zsh starship yazi eza bat btop micro vim github-cli lazygit mise
  firefox chromium
)
# Resolve these against enabled repositories first, then fall back to the AUR.
community_packages=(dosbox-staging protonup-qt openshot-bin visual-studio-code-bin)

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

enable_multilib() {
  awk '
    /^\[multilib\][[:space:]]*$/ {active=1}
    {print}
    END {if (!active) print "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist"}
  ' "$1"
}

configure_mdns() {
  awk '
    /^hosts:/ && !/mdns/ {
      for (i=2; i<=NF; i++) {
        if ($i == "resolve" || $i == "dns") {
          $i = "mdns_minimal [NOTFOUND=return] " $i
          break
        }
      }
    }
    {print}
  ' "$1"
}

boot_options() {
  local word
  for word in $(< "$1"); do
    case "$word" in BOOT_IMAGE=*|initrd=*) continue ;; esac
    printf '%s ' "$word"
  done
  printf '\n'
}

backup() {
  local file=$1
  if [[ -e $file || -L $file ]]; then
    sudo cp -a -- "$file" "$file.post-arch.$(date +%Y%m%d%H%M%S).$$.bak"
  fi
}

install_config() {
  local src=$1 dest=$2
  if ! sudo cmp -s "$src" "$dest"; then
    backup "$dest"
    sudo install -Dm644 "$src" "$dest"
  fi
}

preview() {
  say 'Official packages'
  printf '%s\n' "${packages[*]}"
  say 'Repository or AUR packages'
  printf '%s\n' "paru ${community_packages[*]}"
  say 'Configuration'
  printf '%s\n' \
    'Enable multilib; perform a full system upgrade.' \
    'Build paru as the regular user, with debug packages disabled for this run.' \
    'Enable NetworkManager, Bluetooth, CUPS, Avahi and time synchronization for next boot.' \
    'Enable the Plasma login manager if no display manager is configured.' \
    'Configure mDNS, zstd zram, zsh, Starship, mise and your aliases.' \
    'Regenerate initramfs and add kernel entries for GRUB or systemd-boot (/boot).' \
    'No package removals. Reboot manually after completion.'
}

main() {
  case "${1:-}" in
    --dry-run) preview; return ;;
    --help|-h) printf 'Usage: bash install.sh [--dry-run|--help]\nRun as a sudo-capable regular user on installed x86_64 Arch.\n'; return ;;
    '') ;;
    *) die "Unknown argument: $1" ;;
  esac
  [[ $# -le 1 ]] || die 'Too many arguments.'
  [[ $EUID -ne 0 ]] || die 'Run as your regular user, without sudo; privileged steps use sudo.'
  [[ -f /etc/arch-release && $(uname -m) == x86_64 ]] || die 'Requires x86_64 Arch Linux.'
  [[ -t 0 ]] || die 'Run in a terminal using bash <(curl -fsSL URL), not curl | bash.'
  command -v sudo >/dev/null || die 'Install sudo and grant your regular user sudo access first.'
  [[ -d /run/systemd/system ]] || die 'Run from the installed system, not an installation chroot.'
  grep -q GenuineIntel /proc/cpuinfo || die 'This profile targets your Intel CPU and AMD GPU.'
  command -v mkinitcpio >/dev/null || die 'This profile currently requires mkinitcpio.'

  preview
  local answer
  read -r -p 'Apply this setup? [y/N] ' answer
  [[ $answer == y || $answer == Y ]] || return 0
  sudo -v

  local boot_mode boot_path
  if sudo test -f /boot/grub/grub.cfg && command -v grub-mkconfig >/dev/null; then
    boot_mode=grub
  elif sudo bootctl is-installed >/dev/null 2>&1; then
    boot_path=$(sudo bootctl --print-boot-path)
    [[ $boot_path == /boot ]] || die 'systemd-boot support requires its boot partition mounted at /boot.'
    mountpoint -q /boot || die '/boot must be mounted before installing kernels.'
    boot_mode=systemd
  else
    die 'Supported bootloaders: existing GRUB, or systemd-boot with boot partition at /boot.'
  fi

  local work
  work=$(mktemp -d -t post-arch.XXXXXXXX)
  # Retain build files on failure so the cause can be inspected.
  trap 'printf "Setup stopped at line %s. Work files: %s\n" "$LINENO" "$work" >&2' ERR

  say 'Enable multilib and install official packages'
  enable_multilib /etc/pacman.conf > "$work/pacman.conf"
  install_config "$work/pacman.conf" /etc/pacman.conf
  sudo pacman -Syu --needed "${packages[@]}"

  say 'Install paru and remaining applications'
  printf 'source /etc/makepkg.conf\nOPTIONS+=(!debug)\n' > "$work/makepkg.conf"
  if ! command -v paru >/dev/null; then
    git clone https://aur.archlinux.org/paru.git "$work/paru"
    less "$work/paru/PKGBUILD"
    read -r -p 'Build and install this paru PKGBUILD? [y/N] ' answer
    [[ $answer == y || $answer == Y ]] || die 'Paru build declined; rerun when ready.'
    (cd "$work/paru" && makepkg --config "$work/makepkg.conf" -si)
  fi
  local package
  for package in "${community_packages[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then
      sudo pacman -S --needed "$package"
    else
      paru -S --needed --makepkgconf "$work/makepkg.conf" "$package"
    fi
  done

  say 'Configure desktop services'
  configure_mdns /etc/nsswitch.conf > "$work/nsswitch.conf"
  install_config "$work/nsswitch.conf" /etc/nsswitch.conf
  printf '[zram0]\ncompression-algorithm = zstd\n' > "$work/zram.conf"
  install_config "$work/zram.conf" /etc/systemd/zram-generator.conf
  sudo systemctl enable NetworkManager.service bluetooth.service cups.service avahi-daemon.service systemd-timesyncd.service
  if [[ ! -e /etc/systemd/system/display-manager.service && ! -L /etc/systemd/system/display-manager.service ]]; then
    if [[ -f /usr/lib/systemd/system/plasmalogin.service ]]; then
      sudo systemctl enable plasmalogin.service
    elif [[ -f /usr/lib/systemd/system/sddm.service ]]; then
      sudo systemctl enable sddm.service
    else
      die 'No supported display manager installed by plasma-meta.'
    fi
  fi

  say 'Configure your shell'
  mkdir -p "$HOME/.config/post-arch"
  local shell_config="$HOME/.config/post-arch/shell.zsh"
  if [[ -e $shell_config ]]; then cp -a "$shell_config" "$shell_config.$(date +%Y%m%d%H%M%S).$$.bak"; fi
  cat > "$shell_config" <<'ZSH'
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
export EDITOR=micro
typeset -U path
path=("$HOME/.local/bin" $path)
alias mi='micro'
alias yz='yazi'
alias ls='eza --icons'
alias lg='lazygit'
alias cat='bat'
ZSH
  # Expand HOME when zsh reads this line, not while generating it.
  # shellcheck disable=SC2016
  local source_line='source "$HOME/.config/post-arch/shell.zsh"'
  if ! grep -Fxq "$source_line" "$HOME/.zshrc" 2>/dev/null; then
    if [[ -e $HOME/.zshrc ]]; then cp -a "$HOME/.zshrc" "$HOME/.zshrc.$(date +%Y%m%d%H%M%S).$$.bak"; fi
    printf '\n%s\n' "$source_line" >> "$HOME/.zshrc"
  fi
  sudo chsh -s /bin/zsh "$(id -un)"

  say 'Configure boot entries for all three kernels'
  if [[ $boot_mode == systemd ]]; then
    local kernel options
    options=$(boot_options /proc/cmdline)
    for kernel in linux linux-lts linux-zen; do
      # Use dedicated presets: retain the existing installer's UKI/preset choices.
      printf "ALL_kver='/boot/vmlinuz-%s'\nPRESETS=('default')\ndefault_image='/boot/initramfs-post-arch-%s.img'\n" "$kernel" "$kernel" > "$work/preset"
      install_config "$work/preset" "/etc/mkinitcpio.d/post-arch-$kernel.preset"
      printf 'title Arch Linux (%s, post-arch)\nlinux /vmlinuz-%s\ninitrd /intel-ucode.img\ninitrd /initramfs-post-arch-%s.img\noptions %s\n' "$kernel" "$kernel" "$kernel" "$options" > "$work/entry"
      install_config "$work/entry" "/boot/loader/entries/post-arch-$kernel.conf"
    done
  fi
  sudo mkinitcpio -P
  if [[ $boot_mode == grub ]]; then
    backup /boot/grub/grub.cfg
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
  trap - ERR
  say "Setup complete. Reboot when ready. Work files retained at $work"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
