{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;

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
