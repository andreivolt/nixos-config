{ config, lib, pkgs, ... }:

{
  # Waybar configuration via home-manager
  home-manager.users.andrei = { config, pkgs, ... }: {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };

    # Auto-restart waybar when config files change
    systemd.user.paths.waybar-config-watcher = {
      Unit.Description = "Watch waybar config for changes";
      Path.PathChanged = [
        "/home/andrei/dev/nixos-config/linux/waybar/style.css"
        "/home/andrei/dev/nixos-config/linux/waybar/config.json"
      ];
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.services.waybar-config-watcher = {
      Unit.Description = "Reload waybar on config change";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.procps}/bin/pkill -SIGUSR2 waybar";
      };
    };

    # Config files from external sources
    xdg.configFile = {
      # Out-of-store symlinks for live editing without rebuild
      "waybar/config".source = config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/waybar/config.json";
      "waybar/style.css" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/waybar/style.css";
        onChange = "${pkgs.systemd}/bin/systemctl --user restart waybar || true";
      };

    };
  };
}
