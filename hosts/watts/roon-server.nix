{ config, lib, pkgs, ... }:

{
  # Roon Server - music streaming server
  services.roon-server = {
    enable = true;
    openFirewall = true;
  };

  # Create stable device symlink for iFi DAC (vendor 20b1, product 3008)
  services.udev.extraRules = ''
    SUBSYSTEM=="sound", ATTR{id}=="Audio", ATTRS{idVendor}=="20b1", ATTRS{idProduct}=="3008", SYMLINK+="ifi-dac", TAG+="systemd"
  '';

  # Bind roon-server to DAC via stable symlink
  systemd.services.roon-server = {
    bindsTo = [ "dev-ifi\\x2ddac.device" ];
    after = [ "dev-ifi\\x2ddac.device" ];
  };

  # Allow unfree package
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "roon-server"
    ];
}
