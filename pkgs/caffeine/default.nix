{
  lib,
  python3,
  systemd,
  socat,
  writeShellScriptBin,
  symlinkJoin,
}:
let
  python = python3.withPackages (ps: [ ps.dbus-python ps.pygobject3 ]);

  caffeine-tray = writeShellScriptBin "caffeine-tray" ''
    exec ${python}/bin/python3 ${./caffeine-tray.py}
  '';

  caffeine-cli = writeShellScriptBin "caffeine" ''
    SOCK="/run/user/$(id -u)/caffeine.sock"

    if [ ! -S "$SOCK" ]; then
      # fallback: direct systemctl control
      case "''${1:-status}" in
        on)     ${systemd}/bin/systemctl --user stop hypridle; echo "OK" ;;
        off)    ${systemd}/bin/systemctl --user start hypridle; echo "OK" ;;
        toggle)
          if ! ${systemd}/bin/systemctl --user is-active --quiet hypridle; then
            ${systemd}/bin/systemctl --user start hypridle; echo "OFF"
          else
            ${systemd}/bin/systemctl --user stop hypridle; echo "ON"
          fi
          ;;
        status)
          if ! ${systemd}/bin/systemctl --user is-active --quiet hypridle; then
            echo "ON"
          else
            echo "OFF"
          fi
          ;;
        *)
          echo "Usage: caffeine [on|off|toggle|status|MINUTES]"
          exit 1
          ;;
      esac
      exit 0
    fi

    CMD="''${1:-status}"
    echo "$CMD" | ${socat}/bin/socat - UNIX-CONNECT:"$SOCK"
  '';

in
symlinkJoin {
  name = "caffeine";
  paths = [ caffeine-tray caffeine-cli ];
  meta = {
    description = "Caffeine systray app and CLI for toggling hypridle";
    platforms = lib.platforms.linux;
  };
}
