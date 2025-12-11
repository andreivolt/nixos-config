{pkgs}:
pkgs.writeShellScriptBin "vnc" ''
  host="''${1:-}"
  [ -z "$host" ] && echo "Usage: vnc <hostname>" && exit 1

  unit="vnc-tunnel-$$"

  # Start SSH tunnel as a transient systemd service
  ${pkgs.systemd}/bin/systemd-run --user --unit="$unit" \
    ${pkgs.openssh}/bin/ssh -L 5901:localhost:5900 -N "$host"

  sleep 1

  # Run wlvncc (blocks until window closed)
  ${pkgs.wlvncc}/bin/wlvncc localhost 5901 || true

  # Stop the tunnel
  ${pkgs.systemd}/bin/systemctl --user stop "$unit" 2>/dev/null
''
