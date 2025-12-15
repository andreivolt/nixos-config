{
  pkgs,
  config,
  lib,
  ...
}: {
  # Enable iio-sensor-proxy for accelerometer access
  hardware.sensor.iio.enable = true;

  # Allow user to reset Wacom USB device without sudo
  # (needed for hypridle DPMS resume to fix zombie touchscreen)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="056a", ATTR{idProduct}=="5087", RUN+="${pkgs.coreutils}/bin/chmod 666 %S%p/authorized"
  '';

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
  };
}
