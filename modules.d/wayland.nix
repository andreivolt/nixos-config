{ config, lib, pkgs, ... }:

with lib;

let
  url = "https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz";
  waylandOverlay = (import (builtins.fetchTarball url));
in {
  nixpkgs.overlays = [ waylandOverlay ];

  programs.sway-beta.enable = true;

  programs.sway-beta.extraPackages = with pkgs; [
    waybar # polybar-alike
    i3status-rust # simpler bar written in Rust

    grim     # screen image capture
    slurp    # screen are selection tool
    mako     # notification daemon
    wlstream # screen recorder
    oguri    # animated background utility
    wmfocus  # fast window picker utility
    kanshi   # dynamic display configuration helper
    redshift-wayland # patched to work with wayland gamma protocol
  ];

  environment.systemPackages = with pkgs; [
    # other compositors/window-managers
    dmenu
    wayfire  # 3D wayland compositor
    rxvt
    xwayland
    waybox   # An openbox clone on Wayland
    bspwc    # Wayland compositor based on BSPWM
  ];

  environment.variables.GDK_SCALE = "2";

  services.xserver.videoDrivers = [ "nouveau" ];

  services.compton.extraOptions = mkAfter ''
    backend = "xr_glx_hybrid";
    glx-no-stencil = true;
    glx-swap-method = "copy";
    paint-on-overlay = true;
    unredir-if-possible = true;
    vsync = "drm";
    shadow-radius = 10;
  '';

}
