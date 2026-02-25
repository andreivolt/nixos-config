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
      After = ["tray.target"];
      Requires = ["tray.target"];
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

  systemd.user.services.cpu-monitor-tray = {
    Unit = {
      Description = "CPU sparkline tray icon";
      After = ["tray.target"];
      Requires = ["tray.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.system-monitor-tray}/bin/system-monitor-tray cpu";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.mem-monitor-tray = {
    Unit = {
      Description = "Memory sparkline tray icon";
      After = ["tray.target"];
      Requires = ["tray.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.system-monitor-tray}/bin/system-monitor-tray mem";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.battery-tray = {
    Unit = {
      Description = "Battery circular progress tray icon";
      After = ["tray.target"];
      Requires = ["tray.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.battery-tray}/bin/battery-tray";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.mullvad-tray = {
    Unit = {
      Description = "Mullvad VPN systray applet";
      After = ["tray.target"];
      Requires = ["tray.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.mullvad-tray}/bin/mullvad-tray";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  xdg.enable = true;
  xdg.userDirs.enable = true;
}
