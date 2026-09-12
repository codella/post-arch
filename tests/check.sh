#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source ./install.sh
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
printf '[options]\n#[multilib]\n#Include = /etc/pacman.d/mirrorlist\n' > "$test_dir/input"
enable_multilib "$test_dir/input" > "$test_dir/first"
enable_multilib "$test_dir/first" > "$test_dir/second"
cmp "$test_dir/first" "$test_dir/second"
[[ $(grep -c '^\[multilib\]$' "$test_dir/first") == 1 ]]
printf 'hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns\n' > "$test_dir/input"
configure_mdns "$test_dir/input" > "$test_dir/first"
configure_mdns "$test_dir/first" > "$test_dir/second"
cmp "$test_dir/first" "$test_dir/second"
grep -Fq 'mdns_minimal [NOTFOUND=return] resolve' "$test_dir/first"
printf 'BOOT_IMAGE=/vmlinuz-linux root=UUID=test rootflags=subvol=@ rw initrd=\\initramfs.img quiet\n' > "$test_dir/input"
[[ $(boot_options "$test_dir/input") == 'root=UUID=test rootflags=subvol=@ rw quiet ' ]]
for required in linux linux-lts linux-zen micro vim firefox chromium; do
  [[ " ${packages[*]} " == *" $required "* ]]
done
for excluded in nano htop zellij paru-debug; do
  [[ " ${packages[*]} ${community_packages[*]} " != *" $excluded "* ]]
done
bash install.sh --dry-run > "$test_dir/preview"
grep -q 'No package removals' "$test_dir/preview"
if bash install.sh --invalid >/dev/null 2>&1; then exit 1; fi
printf 'All checks passed.\n'
