{ config, lib, pkgs, ... }:

{
  # Roon Server - music streaming server
  services.roon-server = {
    enable = true;
    openFirewall = true;
  };

  # Only run roon-server when iFi DAC is connected
  # Fixes CPU spin bug when device disconnects mid-session
  systemd.services.roon-server = {
    bindsTo = [ "sys-devices-pci0000:00-0000:00:1d.0-0000:06:00.0-0000:07:02.0-0000:3c:00.0-usb3-3\\x2d1-3\\x2d1.3-3\\x2d1.3:1.0-sound-card0-controlC0.device" ];
    after = [ "sys-devices-pci0000:00-0000:00:1d.0-0000:06:00.0-0000:07:02.0-0000:3c:00.0-usb3-3\\x2d1-3\\x2d1.3-3\\x2d1.3:1.0-sound-card0-controlC0.device" ];
  };

  # Allow unfree package
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "roon-server"
    ];
}
