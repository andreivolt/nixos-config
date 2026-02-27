{ pkgs, config, lib, ... }: let
  mpv-cast = pkgs.writeShellScriptBin "mpv-cast" ''
    set -euo pipefail
    [[ $# -eq 0 ]] && { echo "usage: mpv-cast <url>"; exit 1; }
    ${pkgs.jq}/bin/jq -n --arg url "$1" \
      '{"command":["loadfile",$url,"replace"]}' \
      | ssh watts "socat - /tmp/mpv-cast-receiver" >/dev/null
  '';
in {
  environment.systemPackages = [ mpv-cast ];

  home-manager.sharedModules = lib.mkIf (config.networking.hostName == "watts") [{
    systemd.user.services.mpv-cast-receiver = {
      Unit = {
        Description = "mpv cast receiver";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.mpv}/bin/mpv --idle --force-window=no --input-ipc-server=/tmp/mpv-cast-receiver";
        Restart = "always";
        RestartSec = 1;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  }];
}
