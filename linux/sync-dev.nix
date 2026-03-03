{config, lib, pkgs, ...}:

{
  home-manager.users.andrei = {
    systemd.user.services.sync-dev = {
      Unit = {
        Description = "RClone bidirectional sync for ~/dev";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = let
          script = pkgs.writeShellScript "sync-dev" ''
            RESYNC_FLAG=""
            LISTING="$HOME/.cache/rclone/bisync/home_andrei_dev..gdrive_dev.path1.lst"
            if [ ! -f "$LISTING" ]; then
              RESYNC_FLAG="--resync --resync-mode newer"
            fi
            ${pkgs.rclone}/bin/rclone bisync /home/andrei/dev gdrive:dev \
              --create-empty-src-dirs \
              --compare size,modtime \
              --slow-hash-sync-only \
              --resilient \
              --exclude .clj-kondo/ \
              --exclude .cpcache/ \
              --exclude .direnv/ \
              --exclude .gradle/ \
              --exclude .lsp/ \
              --exclude .shadow-cljs/ \
              --exclude node_modules/ \
              --exclude target/ \
              $RESYNC_FLAG \
              -v
          '';
        in "${script}";
      };
    };

    systemd.user.timers.sync-dev = {
      Unit.Description = "Periodic bidirectional sync for ~/dev";
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
