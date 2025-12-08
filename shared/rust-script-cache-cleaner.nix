{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;

  cleanerScript = pkgs.writeShellScript "rust-script-cache-cleaner" ''
    projects_dir="$HOME/.cache/rust-script/projects"
    binaries_dir="$HOME/.cache/rust-script/binaries/release"

    clean_orphans() {
      [[ -d "$projects_dir" ]] || return
      for project in "$projects_dir"/*/; do
        [[ -d "$project" ]] || continue
        source_path=$(${pkgs.gnugrep}/bin/grep '^path = ' "$project/Cargo.toml" 2>/dev/null | cut -d'"' -f2)
        if [[ -n "$source_path" && ! -f "$source_path" ]]; then
          hash=$(basename "$project")
          echo "Removing orphaned cache: $source_path"
          rm -rf "$project"
          rm -f "$binaries_dir"/*"$hash"*
        fi
      done
    }

    clean_orphans

    ${lib.optionalString isLinux ''
      ${pkgs.inotify-tools}/bin/inotifywait -m -e delete,move "$HOME/bin" 2>/dev/null |
      while read -r dir event file; do
        clean_orphans
      done
    ''}
  '';
in
lib.mkMerge [
  (lib.mkIf isDarwin {
    launchd.agents.rust-script-cache-cleaner = {
      enable = true;
      config = {
        ProgramArguments = [ "${cleanerScript}" ];
        WatchPaths = [ "/Users/andrei/bin" ];
        EnvironmentVariables.PATH = "/run/current-system/sw/bin:/usr/bin:/bin";
      };
    };
  })

  (lib.mkIf isLinux {
    systemd.user.services.rust-script-cache-cleaner = {
      Unit.Description = "Rust Script Cache Cleaner";
      Service = {
        ExecStart = "${cleanerScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  })
]
