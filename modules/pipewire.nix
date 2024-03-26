{ pkgs, ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    # config.pipewire-pulse = {
    #   "context.modules" = [
    #     { name = "libpipewire-module-protocol-native"; }
    #     { name = "libpipewire-module-profiler"; }
    #     { name = "libpipewire-module-metadata"; }
    #     { name = "libpipewire-module-spa-device-factory"; }
    #     { name = "libpipewire-module-spa-node-factory"; }
    #     { name = "libpipewire-module-client-node"; }
    #     { name = "libpipewire-module-client-device"; }
    #     {
    #       name = "libpipewire-module-portal";
    #       flags = [ "ifexists" "nofail" ];
    #     }
    #     {
    #       name = "libpipewire-module-access";
    #       args = {};
    #     }
    #     { name = "libpipewire-module-adapter"; }
    #     { name = "libpipewire-module-link-factory"; }
    #     { name = "libpipewire-module-session-manager"; }

    #     {
    #       name = "libpipewire-module-protocol-pulse";
    #       args = {
    #         "server.address" = [ "unix:native" "tcp:4713" ];
    #       };
    #     }
    #   ];
    # };

    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;

    # media-session.config.bluez-monitor.rules = [
    #   # {
    #   #   matches = [ { "node.name" = "alsa_output.usb-Bose_Corporation_Bose_Revolve__SoundLink_Q82120191077506011A0510-00.analog-stereo"; } ];
    #   #   actions = {
    #   #     "update-props" = {
    #   #         "audio.format" = "s16le";
    #   #         "audio.rate" = 48000;
    #   #     };
    #   #   };
    #   # }
    #   {
    #     matches = [ { "device.name" = "~bluez_card.*"; } ];
    #     actions = {
    #       "update-props" = {
    #         "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
    #         "bluez5.msbc-support" = true;
    #         "bluez5.sbc-xq-support" = true;
    #       };
    #     };
    #   }
    #   {
    #     matches = [
    #       { "node.name" = "~bluez_input.*"; }
    #       { "node.name" = "~bluez_output.*"; }
    #     ];
    #     actions = {
    #       "node.pause-on-idle" = false;
    #     };
    #   }
    # ];
    # };
  };
}
