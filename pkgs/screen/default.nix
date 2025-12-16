{
  writeShellScriptBin,
  hyprland,
}:
writeShellScriptBin "screen" ''
  # Find Hyprland socket for SSH sessions
  if [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | head -1)
    export HYPRLAND_INSTANCE_SIGNATURE
  fi

  case "''${1:-}" in
    on)  ${hyprland}/bin/hyprctl dispatch dpms on ;;
    off) sleep 0.5 && ${hyprland}/bin/hyprctl dispatch dpms off ;;
    *)   echo "Usage: screen [on|off]"; exit 1 ;;
  esac
''
