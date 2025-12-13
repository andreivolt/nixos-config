#!/usr/bin/env bash
set -euo pipefail

REMOTE="andrei@watts"
BACKUP="/tmp/riva-backup"
CRYPT=/dev/mapper/cryptroot

read -p "Wipe /dev/nvme0n1p6? [y/N] " -n1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1
ssh -o ConnectTimeout=5 "$REMOTE" true

mount /dev/nvme0n1p6 /mnt
ssh "$REMOTE" "mkdir -p $BACKUP"
for name in persist home; do
    for sv in "@$name" "$name"; do [ -d "/mnt/$sv" ] && break; done
    [ -d "/mnt/$sv" ] || continue
    btrfs subvolume snapshot -r "/mnt/$sv" "/mnt/$name-snap"
    btrfs send "/mnt/$name-snap" | zstd | ssh "$REMOTE" "cat > $BACKUP/$name.btrfs"
    btrfs subvolume delete "/mnt/$name-snap"
done
umount /mnt

nix-shell -p git --run "git clone https://github.com/andreivolt/nixos-config /tmp/config"
nix run github:nix-community/disko -- --mode disko --flake /tmp/config#riva
umount -R /mnt 2>/dev/null || true

mkdir -p /tmp/btrfs
mount -o subvol=/ $CRYPT /tmp/btrfs
btrfs subvolume delete /tmp/btrfs/{persist,home} 2>/dev/null || true
for name in persist home; do
    ssh "$REMOTE" "cat $BACKUP/$name.btrfs" | zstd -d | btrfs receive /tmp/btrfs/
    btrfs subvolume snapshot "/tmp/btrfs/$name-snap" "/tmp/btrfs/$name"
    btrfs subvolume delete "/tmp/btrfs/$name-snap"
done
umount /tmp/btrfs

mount -o subvol=root $CRYPT /mnt
mkdir -p /mnt/{boot,nix,persist,home,var/log,swap}
mount /dev/nvme0n1p4 /mnt/boot
for sv in nix persist home swap; do mount -o subvol=$sv $CRYPT /mnt/$sv; done
mount -o subvol=log $CRYPT /mnt/var/log

mkdir -p /mnt/persist/etc
rm -rf /mnt/persist/etc/nixos
cp -r /tmp/config /mnt/persist/etc/nixos
nixos-install --flake /tmp/config#riva --no-root-passwd

ssh "$REMOTE" "rm -rf $BACKUP"
