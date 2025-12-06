{ config, lib, pkgs, inputs, ... }:

let
  hyprlandPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in {
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
  # Config is in ~/.config/hypr/main.conf, sourced via extraConfig
  home-manager.users.andrei = { ... }: {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;  # Use system package
      portalPackage = null;
      systemd.enable = false;  # UWSM handles this
      plugins = [
        hyprlandPlugins.hyprbars
      ];
      extraConfig = ''
        source = ./main.conf

        # Trayscale - float near tray
        windowrule = float, class:^(dev.deedles.Trayscale)$
        windowrule = size 400 500, class:^(dev.deedles.Trayscale)$
        windowrule = move 100%-410 40, class:^(dev.deedles.Trayscale)$
      '';
    };
  };
}
