{
  pkgs,
  config,
  lib,
  ...
}: {
  # Enable iio-sensor-proxy for accelerometer access
  hardware.sensor.iio.enable = true;

  # Reset Wacom USB device after resume from suspend
  # The device gets into a zombie state where it appears connected but generates no events
  # (ISH sensor hub resume timeout leaves USB devices in partially-initialized state)
  powerManagement.resumeCommands = ''
    # Find and reset Wacom touchscreen USB device
    for dev in /sys/bus/usb/devices/*; do
      if [ -f "$dev/idVendor" ] && [ -f "$dev/idProduct" ]; then
        vendor=$(cat "$dev/idVendor" 2>/dev/null)
        product=$(cat "$dev/idProduct" 2>/dev/null)
        if [ "$vendor" = "056a" ] && [ "$product" = "5087" ]; then
          echo "Resetting Wacom touchscreen at $dev"
          echo 0 > "$dev/authorized" 2>/dev/null
          sleep 0.5
          echo 1 > "$dev/authorized" 2>/dev/null
        fi
      fi
    done
  '';

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

    # Auto-rotation script using iio-sensor-proxy D-Bus events (no polling)
    home.file.".local/bin/hypr-autorotate" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Auto-rotation for Hyprland using iio-sensor-proxy events
        # Event-driven via monitor-sensor, no polling needed

        rotate() {
          local orientation=$1
          local transform

          case "$orientation" in
            normal)    transform=0 ;;
            bottom-up) transform=2 ;;
            left-up)   transform=1 ;;
            right-up)  transform=3 ;;
            *)         return ;;
          esac

          hyprctl keyword monitor "eDP-1,transform,$transform"
          hyprctl keyword 'device[wacom-pen-and-multitouch-sensor-finger]:transform' "$transform"
          hyprctl keyword 'device[wacom-pen-and-multitouch-sensor-pen]:transform' "$transform"
        }

        monitor-sensor | while read -r line; do
          # Match both initial state and change events:
          #   "=== Has accelerometer (orientation: normal)"
          #   "    Accelerometer orientation changed: left-up"
          case "$line" in
            *"orientation changed:"*)
              orientation="''${line##*: }"
              rotate "$orientation"
              ;;
            *"(orientation:"*)
              orientation="''${line##*(orientation: }"
              orientation="''${orientation%%,*}"  # strip ", tilt: ..." if present
              orientation="''${orientation%)}"    # strip trailing ) if no comma
              rotate "$orientation"
              ;;
          esac
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
