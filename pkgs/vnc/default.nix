{pkgs}:
pkgs.writeShellScriptBin "vnc" ''
  set -euo pipefail

  host="''${1:-}"
  [ -z "$host" ] && echo "Usage: vnc <hostname>" && exit 1

  cleanup() {
    [ -n "''${pid:-}" ] && kill "$pid" 2>/dev/null
  }
  trap cleanup EXIT INT TERM

  ${pkgs.openssh}/bin/ssh -L 5900:localhost:5900 -N "$host" & pid=$!
  sleep 0.5
  ${pkgs.wlvncc}/bin/wlvncc localhost
''
