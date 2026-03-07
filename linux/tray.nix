# System tray applets (caffeine, monitors, battery, mic, mullvad)
{ pkgs, ... }: {
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

  systemd.user.services.cpu-mem-monitor-tray = {
    Unit = {
      Description = "CPU/Memory dual-bar tray icon";
      After = ["tray.target"];
      Requires = ["tray.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.system-monitor-tray}/bin/system-monitor-tray cpu-mem";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  systemd.user.services.net-monitor-tray = {
    Unit = {
      Description = "Network up/down dual-bar tray icon";
      After = ["tray.target"];
      Requires = ["tray.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.system-monitor-tray}/bin/system-monitor-tray net";
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

  systemd.user.services.mic-indicator = {
    Unit = {
      Description = "Microphone recording tray indicator";
      After = ["tray.target" "pipewire.service"];
      Requires = ["tray.target"];
      BindsTo = ["pipewire.service"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.andrei.mic-indicator}/bin/mic-indicator";
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
}
