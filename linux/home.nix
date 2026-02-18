# Shared home-manager config for linux systems
{ config, inputs }:

{pkgs, ...}: {
  imports = [
    ./hyprland/pin-auto.nix
    ./mime-apps.nix
    ./swayimg.nix
    ./xdg-places
    ./zathura.nix
  ];

  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config = config.nixpkgs.config;
  nixpkgs.overlays = config.nixpkgs.overlays;

  home.packages =
    (import "${inputs.self}/packages/core.nix" pkgs)
    ++ (import "${inputs.self}/packages/lsp.nix" pkgs)
    ++ (import "${inputs.self}/packages/linux.nix" pkgs)
    ++ (import "${inputs.self}/packages/workstation.nix" pkgs)
    ++ (import "${inputs.self}/packages/gui.nix" pkgs);

  services.playerctld.enable = true;

  systemd.user.services.caffeine-tray = {
    Unit = {
      Description = "Caffeine systray applet";
      After = ["ironbar.service"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.caffeine}/bin/caffeine-tray";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  xdg.enable = true;
  xdg.userDirs.enable = true;
}
