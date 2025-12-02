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
        ACCEL_PATH="/sys/bus/iio/devices/iio:device0"
        THRESHOLD=15000
        POLL_INTERVAL=0.5

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

          # Determine orientation based on gravity direction
          if (( abs_y > abs_x )); then
            if (( y < -THRESHOLD )); then
              echo "normal"
            elif (( y > THRESHOLD )); then
              echo "bottom-up"
            fi
          else
            if (( x < -THRESHOLD )); then
              echo "right-up"
            elif (( x > THRESHOLD )); then
              echo "left-up"
            fi
          fi
        }

        rotate_screen() {
          local orientation=$1
          local transform

          # External monitor: 3840x2160 @ 1.6 = 2400x1350 effective
          # Internal: 2560x1440 @ 1.6 = 1600x900 effective (or 900x1600 when rotated 90°)
          EXTERNAL="DP-1"

          case "$orientation" in
            normal)
              # External above, laptop below (centered)
              transform=0
              hyprctl --batch "keyword monitor $EXTERNAL,preferred,0x0,1.6 ; keyword monitor $INTERNAL_DISPLAY,preferred,400x1350,1.6,transform,$transform"
              ;;
            bottom-up)
              # Laptop upside down, positioned below external (so mouse moves DOWN to reach it)
              transform=2
              hyprctl --batch "keyword monitor $EXTERNAL,preferred,0x0,1.6 ; keyword monitor $INTERNAL_DISPLAY,preferred,400x1350,1.6,transform,$transform"
              ;;
            left-up)
              # Laptop rotated 90° CCW (900x1600), external to the right
              transform=1
              hyprctl --batch "keyword monitor $INTERNAL_DISPLAY,preferred,0x0,1.6,transform,$transform ; keyword monitor $EXTERNAL,preferred,900x0,1.6"
              ;;
            right-up)
              # Laptop rotated 90° CW (900x1600), external to the left
              transform=3
              hyprctl --batch "keyword monitor $EXTERNAL,preferred,0x0,1.6 ; keyword monitor $INTERNAL_DISPLAY,preferred,2400x0,1.6,transform,$transform"
              ;;
            *)
              return
              ;;
          esac
        }

        # Wait for accelerometer
        while [[ ! -f "$ACCEL_PATH/in_accel_x_raw" ]]; do
          sleep 1
        done

        # Main loop
        while true; do
          orientation=$(get_orientation)
          if [[ -n "$orientation" && "$orientation" != "$last_orientation" ]]; then
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
        WantedBy = [ "hyprland-session.target" ];
      };
    };
  };
}
