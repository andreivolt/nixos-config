# Hardware configuration for OCI VM.Standard.E2.1.Micro
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # Root filesystem
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/sda15";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  # No hardware clock in VM
  swapDevices = [];

  # Network uses DHCP
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
