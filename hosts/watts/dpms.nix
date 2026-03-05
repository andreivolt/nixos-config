# DPMS control command - works both locally and via SSH
{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "dpms" ''
      set -euo pipefail

      : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
      export XDG_RUNTIME_DIR

      # Find the most recent Hyprland instance socket
      HYPR_DIR="$XDG_RUNTIME_DIR/hypr"
      if [ ! -d "$HYPR_DIR" ]; then
        echo "No Hyprland instance found" >&2
        exit 1
      fi

      # Pick the newest socket directory
      export HYPRLAND_INSTANCE_SIGNATURE
      HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$HYPR_DIR" | head -1)

      if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "No Hyprland instance found" >&2
        exit 1
      fi

      case "''${1:-}" in
        off|on|toggle)
          exec ${pkgs.hyprland}/bin/hyprctl dispatch dpms "$1"
          ;;
        "")
          exec ${pkgs.hyprland}/bin/hyprctl dispatch dpms off
          ;;
        *)
          echo "Usage: dpms [off|on|toggle]" >&2
          exit 1
          ;;
      esac
    '')
  ];
}
