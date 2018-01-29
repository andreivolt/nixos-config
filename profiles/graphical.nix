{ config, pkgs, ... }:

let
  libinput-gestures = pkgs.callPackage ../packages/libinput-gestures/default.nix {};

in {
  imports =
    [
      ../udiskie.nix
    ];

  environment.systemPackages = with pkgs; [
    alacritty
    chromium
    dunst
    firefox-devedition-bin
    gcolor2
    haskellPackages.xmobar
    inkscape
    libinput-gestures
    libnotify
    libreoffice-fresh
    maim
    mpv
    mupdf
    redshift
    rofi
    scrot
    setroot
    slop
    sshuttle
    sxhkd
    sxiv
    #tdesktop
    torbrowser
    vaapiVdpau
    virt-viewer
    wmctrl
    xbindkeys
    xclip
    xdotool
    xfce.thunar
    xmind
    xorg.xev
    xorg.xinput
    xorg.xrandr
    xorg.xset
    xsel
    zathura
  ];

  nixpkgs.config.zathura.useMupdf = true;

  services.udisks2.enable = true;

  services.xserver = {
    enable = true;
    layout = "fr";

    libinput = {
      enable = true;
      naturalScrolling = true;
      accelSpeed = "0.4";
    };

    displayManager = {
      auto = {
        enable = true;
        user = "avo";
      };
      sessionCommands = ''
        ${pkgs.sxhkd}/bin/sxhkd &
        ${pkgs.dropbox}/bin/dropbox start &
      '';
    };

    windowManager = {
      default = "xmonad";
      xmonad  = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = haskellPackages: [
          haskellPackages.xmobar
        ];
      };
    };
  };
}
