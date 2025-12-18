{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;

    # Reduce buffer size for lower latency (~20-30ms improvement)
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
      };
    };

    # Auto-switch to Bluetooth audio when a device connects
    # Sets high priority (2000) so Bluetooth becomes default sink
    wireplumber.extraConfig."51-bluetooth-auto-switch" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
      "monitor.bluez.rules" = [
        {
          matches = [{ "device.name" = "~bluez_card.*"; }];
          actions = {
            update-props = {
              "bluez5.auto-connect" = [ "a2dp_sink" ];
            };
          };
        }
        {
          matches = [{ "node.name" = "~bluez_output.*"; }];
          actions = {
            update-props = {
              "node.priority.session" = 2000;
            };
          };
        }
      ];
    };
  };
}
