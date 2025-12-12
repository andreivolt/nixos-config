{
  pkgs,
  config,
  lib,
  ...
}: {
  # Enable iio-sensor-proxy for accelerometer access
  hardware.sensor.iio.enable = true;

  # Generate Hyprland touch config to map device to laptop screen
  home-manager.users.andrei = { pkgs, ... }: {
    wayland.windowManager.hyprland.extraConfig = ''
      source = ~/.config/hypr/touch.conf
    '';

    xdg.configFile."hypr/touch.conf".text = ''
      device {
        name = wacom-pen-and-multitouch-sensor-finger
        output = eDP-1
      }

      device {
        name = wacom-pen-and-multitouch-sensor-pen
        output = eDP-1
      }
    '';

    # Auto-rotation script reading accelerometer directly from sysfs
    home.file.".local/bin/hypr-autorotate" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Auto-rotation for Hyprland reading accelerometer from sysfs
        # Monitors accelerometer and rotates eDP-1 display + touch input

        INTERNAL_DISPLAY="eDP-1"
        THRESHOLD=15000
        POLL_INTERVAL=0.5

        # find lid accelerometer (X1 Yoga has base + lid accels, we want lid = last one)
        find_accel_device() {
          local found=""
          for dev in /sys/bus/iio/devices/iio:device*; do
            if [[ -f "$dev/name" ]] && grep -q accel "$dev/name" 2>/dev/null; then
              found="$dev"
            fi
          done
          [[ -n "$found" ]] && echo "$found" && return 0
          return 1
        }

        ACCEL_PATH=""
        last_orientation=""

        get_orientation() {
          local x y z abs_x abs_y abs_z
          x=$(cat "$ACCEL_PATH/in_accel_x_raw" 2>/dev/null) || return 1
          y=$(cat "$ACCEL_PATH/in_accel_y_raw" 2>/dev/null) || return 1
          z=$(cat "$ACCEL_PATH/in_accel_z_raw" 2>/dev/null) || return 1

          # Get absolute values
          abs_x=''${x#-}
          abs_y=''${y#-}
          abs_z=''${z#-}

          # If Z axis dominates (screen flat), keep current orientation
          if (( abs_z > abs_x && abs_z > abs_y )); then
            echo "$last_orientation"
            return
          fi

          # Determine orientation based on gravity direction (lid accelerometer is inverted)
          if (( abs_y > abs_x )); then
            if (( y < -THRESHOLD )); then
              echo "bottom-up"
            elif (( y > THRESHOLD )); then
              echo "normal"
            fi
          else
            if (( x < -THRESHOLD )); then
              echo "left-up"
            elif (( x > THRESHOLD )); then
              echo "right-up"
            fi
          fi
        }

        rotate_screen() {
          local orientation=$1
          local transform

          case "$orientation" in
            normal)    transform=0 ;;
            bottom-up) transform=2 ;;
            left-up)   transform=1 ;;
            right-up)  transform=3 ;;
            *)         return ;;
          esac

          # only change transform, don't touch monitor positions
          hyprctl keyword monitor "$INTERNAL_DISPLAY,transform,$transform"
        }

        # wait for accelerometer device to appear
        while true; do
          ACCEL_PATH=$(find_accel_device) && break
          sleep 1
        done

        # Main loop
        while true; do
          orientation=$(get_orientation)
          if [[ -n "$orientation" ]]; then
            # always apply transform (hyprland config reload can reset it)
            rotate_screen "$orientation"
            last_orientation="$orientation"
          fi
          sleep "$POLL_INTERVAL"
        done
      '';
    };

    # Systemd user service for auto-rotation
    systemd.user.services.hypr-autorotate = {
      Unit = {
        Description = "Hyprland auto-rotation for tablet mode";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "%h/.local/bin/hypr-autorotate";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
