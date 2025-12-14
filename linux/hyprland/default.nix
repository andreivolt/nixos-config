{ config, lib, pkgs, inputs, ... }:

let
  hyprlandPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./vars.nix
  ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
    package = hyprlandPkgs.hyprland;
    portalPackage = hyprlandPkgs.xdg-desktop-portal-hyprland;
  };

  services.hypridle.enable = true;

  programs.hyprlock.enable = true;

  environment.systemPackages = with pkgs; [
    hyprshot
  ] ++ (with hyprlandPkgs; [
    hyprland-qtutils
  ]);

  # Use home-manager's hyprland module to load plugins (ensures version match)
  # Config files are symlinked from nixos-config repo for live editing
  home-manager.users.andrei = { config, lib, ... }: {
    # Symlink config files from repo (out-of-store for live editing)
    home.file.".config/hypr/hyprlock.conf".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hyprlock.conf";
    home.file.".config/hypr/hypridle.conf".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hypridle.conf";
    home.file.".config/hypr/scripts".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/scripts";

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;  # Use system package
      portalPackage = null;
      systemd.enable = false;  # UWSM handles this
      plugins = [
        hyprlandPlugins.hyprbars
        # hyprlandPlugins.hyprexpo  # TODO: causing version mismatch issues
      ];
      extraConfig = ''
        source = ${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hyprland.conf

        # Trayscale - float, pinned, centered, no titlebar
        windowrule = float on, match:class dev.deedles.Trayscale
        windowrule = pin on, match:class dev.deedles.Trayscale
        windowrule = size 400 500, match:class dev.deedles.Trayscale
        windowrule = center on, match:class dev.deedles.Trayscale
        windowrule = hyprbars:no_bar 1, match:class dev.deedles.Trayscale
      '';
    };

    # temporarily disable autoreload during rebuild to prevent layout resets
    # (home-manager recreates symlinks on every activation, triggering hyprland's inotify)
    home.activation.hyprlandPreReload = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${hyprlandPkgs.hyprland}/bin/hyprctl keyword misc:disable_autoreload true 2>/dev/null || true
    '';

    home.activation.hyprlandPostReload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${hyprlandPkgs.hyprland}/bin/hyprctl keyword misc:disable_autoreload false 2>/dev/null || true
    '';
  };
}
