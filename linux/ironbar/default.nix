{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ironbar ];

  home-manager.users.andrei = { config, pkgs, ... }: {
    xdg.configFile = {
      "ironbar/config.json".source = config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/ironbar/config.json";
      "ironbar/style.css".source = config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/ironbar/style.css";
    };

    systemd.user.services.ironbar = {
      Unit = {
        Description = "Ironbar status bar";
        PartOf = [ "graphical-session.target" "tray.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.ironbar}/bin/ironbar";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "graphical-session.target" "tray.target" ];
      };
    };

    # Reload ironbar when config changes (CSS hot-reloads automatically)
    systemd.user.paths.ironbar-config-watcher = {
      Unit.Description = "Watch ironbar config for changes";
      Path.PathChanged = [
        "/home/andrei/dev/nixos-config/linux/ironbar/config.json"
        "/home/andrei/dev/nixos-config/linux/ironbar/style.css"
      ];
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.services.ironbar-config-watcher = {
      Unit.Description = "Reload ironbar on config change";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.ironbar}/bin/ironbar reload";
      };
    };
  };
}
