#!/usr/bin/env -S nix shell nixpkgs#parted -c bash

#  taken from https://github.com/LunNova/nixos-configs/blob/dev/scripts/install/partition.sh
#  and https://lunnova.dev/articles/migrating-main-drive-nixos-tmpfs-root/
set -euo pipefail

# Examples, update before use
prefix=""
suffix=""
device=/dev/sda
swap_size="32GB"

lsblk --output "NAME,SIZE,FSTYPE,FSVER,LABEL,PARTLABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS,DISC-MAX" "$device"

echo "ctrl-c now if this is not the expected target device, enter to continue with partitioning"
read -r -p "Press enter to continue"
read -r -p "Press enter again to continue"

# following the order in https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning
parted -s -a optimal -- "$device" \
    mklabel gpt \
    mkpart "${prefix}primary${suffix}" 512MB "-${swap_size}" \
    mkpart "${prefix}primary${suffix}" linux-swap "-${swap_size}" 100% \
    mkpart ESP fat32 1MB 512MB \
    set 3 esp on