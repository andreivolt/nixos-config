{ pkgs, ... }: {
  # Install swaync package
  environment.systemPackages = [ pkgs.swaynotificationcenter ];

  # SwayNotificationCenter service - Obsidian Aurora theme
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.swaync = {
      enable = true;
      settings = {
        cssPriority = "user";
      };
    };

    # Out-of-store symlink for live CSS editing without rebuild
    xdg.configFile."swaync/style.css".source =
      config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/swaync/style.css";

    # Auto-restart swaync when CSS changes
    systemd.user.paths.swaync-style-watcher = {
      Unit.Description = "Watch swaync style.css for changes";
      Path.PathChanged = [ "/home/andrei/dev/nixos-config/linux/swaync/style.css" ];
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.services.swaync-style-watcher = {
      Unit.Description = "Reload swaync on style change";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user restart swaync";
      };
    };
  };
}
