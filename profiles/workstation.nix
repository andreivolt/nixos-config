{ config, pkgs, ... }:

{
  imports =
    [
      ../adb.nix
      ../alacritty.nix
      ../autocutsel.nix
      ../docker-nginx-proxy.nix
      ../printing.nix
      ../redshift.nix
      ../socks-proxy.nix
    ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };

  hardware = {
    bluetooth.enable = true;

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
   };
  };

  environment.systemPackages = with pkgs; [
    #uzbl
    acpi
    alsaPlugins
    alsaUtils
    dropbox-cli
    dunst
    megatools
    nixops
    pianobar
    ponymix
  ];

  services.unclutter-xfixes.enable = true;

  services.emacs.enable = true;

  systemd.services.docker-nginx-proxy.enable = true;
}
