{ config, lib, ... }:

let
  btrfsDevice = config.fileSystems."/btrfs_root".device;
  rootSubvol = config.btrfsWipe.rootSubvolume;
  oldRootsDir = config.btrfsWipe.oldRootsDirectory;
in {
  options.btrfsWipe = {
    rootSubvolume = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Name of the root subvolume (without leading /)";
    };
    oldRootsDirectory = lib.mkOption {
      type = lib.types.str;
      default = "old_roots";
      description = "Directory name for archived old roots";
    };
  };

  config = {
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /mnt
      mount -o subvol=/ ${btrfsDevice} /mnt

      if [[ -f /mnt/persist/dont-wipe ]]; then
        echo "dont-wipe flag found, skipping root wipe"
        umount /mnt
      else
        if [[ -e /mnt/${rootSubvol} ]]; then
          mkdir -p /mnt/${oldRootsDir}
          timestamp=$(date --date="@$(stat -c %Y /mnt/${rootSubvol})" "+%Y-%m-%d_%H:%M:%S")
          btrfs subvolume snapshot /mnt/${rootSubvol} "/mnt/${oldRootsDir}/$timestamp"
          btrfs subvolume delete /mnt/${rootSubvol}
        fi

        for i in /mnt/${oldRootsDir}/*; do
          if [[ -d "$i" ]]; then
            age=$(($(date +%s) - $(stat -c %Y "$i")))
            if (( age > 2592000 )); then
              echo "Deleting old root: $i"
              btrfs subvolume delete "$i"
            fi
          fi
        done

        btrfs subvolume create /mnt/${rootSubvol}
        umount /mnt
      fi
    '';

    fileSystems."/btrfs_root".neededForBoot = lib.mkForce false;
  };
}
