{ config, lib, pkgs, ... }:

# Native Wayland screensaver with two backends:
# - wgpu: Custom Rust/Vulkan renderer (lowest resource, best quality)
# - mpv: FFmpeg lavfi generators (no compilation needed)
#
# Runs independently of hypridle (ignores idle inhibitors via direct libinput monitoring)

let
  cfg = config.services.glsl-screensaver;

  # Reference to the screensaver from pkgs
  screensaver = pkgs.callPackage ../pkgs/screensaver {};

  screensaverScript = pkgs.writeShellScript "glsl-screensaver" ''
    set -euo pipefail

    TIMEOUT=${toString cfg.timeout}
    MONITOR="${cfg.monitor}"
    VISUAL="${cfg.visual}"
    BACKEND="${cfg.backend}"
    FPS="${toString cfg.fps}"
    PID_FILE="$XDG_RUNTIME_DIR/glsl-screensaver.pid"
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    JQ="${pkgs.jq}/bin/jq"

    kill_screensaver() {
      if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
      fi
    }

    start_screensaver() {
      # Don't start if already running
      if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        return
      fi

      # Get target monitor
      if [ "$MONITOR" = "focused" ]; then
        MONITOR_NAME=$($HYPRCTL monitors -j | $JQ -r '.[] | select(.focused) | .name')
      else
        MONITOR_NAME="$MONITOR"
      fi

      # Get monitor resolution
      MON_INFO=$($HYPRCTL monitors -j | $JQ -r ".[] | select(.name == \"$MONITOR_NAME\")")
      WIDTH=$(echo "$MON_INFO" | $JQ -r '.width')
      HEIGHT=$(echo "$MON_INFO" | $JQ -r '.height')

      if [ "$BACKEND" = "wgpu" ]; then
        # Rust/wgpu backend - native Vulkan, lowest resource usage
        ${screensaver}/bin/screensaver --fps "$FPS" --shader "$VISUAL" &
        echo $! > "$PID_FILE"
      else
        # mpv/lavfi backend - ffmpeg generators
        case "$VISUAL" in
          mandelbrot)
            SOURCE="av://lavfi:mandelbrot=size=''${WIDTH}x''${HEIGHT}:rate=$FPS:maxiter=200"
            ;;
          sierpinski)
            SOURCE="av://lavfi:sierpinski=size=''${WIDTH}x''${HEIGHT}:rate=$FPS"
            ;;
          life)
            SOURCE="av://lavfi:life=size=''${WIDTH}x''${HEIGHT}:rate=$FPS:rule=B3/S23"
            ;;
          cellauto)
            SOURCE="av://lavfi:cellauto=size=''${WIDTH}x''${HEIGHT}:rate=$FPS:rule=30"
            ;;
          plasma)
            SOURCE="av://lavfi:gradients=size=''${WIDTH}x''${HEIGHT}:rate=$FPS:n=4:speed=0.02"
            ;;
          *)
            SOURCE="av://lavfi:mandelbrot=size=''${WIDTH}x''${HEIGHT}:rate=$FPS"
            ;;
        esac

        ${pkgs.mpv}/bin/mpv \
          --fs \
          --fs-screen-name="$MONITOR_NAME" \
          --no-audio \
          --loop-file=inf \
          --really-quiet \
          --no-input-default-bindings \
          --input-conf=/dev/null \
          --no-osc \
          --no-osd-bar \
          --cursor-autohide=always \
          --gpu-context=waylandvk \
          "$SOURCE" &
        echo $! > "$PID_FILE"
      fi
    }

    # Cleanup on exit
    trap kill_screensaver EXIT

    # Monitor input events directly (bypasses all idle inhibitors)
    exec < <(${pkgs.libinput}/bin/libinput debug-events 2>/dev/null)

    while true; do
      if read -t "$TIMEOUT" -r _; then
        # Input detected - kill screensaver
        kill_screensaver
      else
        # Timeout reached - start screensaver
        start_screensaver
      fi
    done
  '';
in
{
  options.services.glsl-screensaver = {
    enable = lib.mkEnableOption "GLSL shader screensaver (native Wayland)";

    backend = lib.mkOption {
      type = lib.types.enum [ "wgpu" "mpv" ];
      default = "wgpu";
      description = ''
        Rendering backend:
        - wgpu: Custom Rust/Vulkan renderer (recommended, lowest resource usage)
        - mpv: FFmpeg lavfi generators (more visual options, no compilation)
      '';
    };

    timeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = "Idle timeout in seconds (default 10 minutes)";
    };

    fps = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Frame rate";
    };

    monitor = lib.mkOption {
      type = lib.types.str;
      default = "focused";
      description = "Monitor ('focused', 'eDP-1', 'DP-1', etc.)";
    };

    visual = lib.mkOption {
      type = lib.types.str;
      default = "plasma";
      description = ''
        Visual style. Available options depend on backend:

        wgpu backend:
        - plasma: Dark warm plasma waves
        - sierpinski: Animated Sierpinski triangle
        - mandelbrot: Zooming Mandelbrot fractal

        mpv backend (all of above plus):
        - life: Conway's Game of Life
        - cellauto: 1D cellular automaton (Rule 30)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # User needs input group for libinput access
    users.users.andrei.extraGroups = [ "input" ];

    # Systemd user service
    systemd.user.services.glsl-screensaver = {
      description = "GLSL shader screensaver";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = screensaverScript;
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
