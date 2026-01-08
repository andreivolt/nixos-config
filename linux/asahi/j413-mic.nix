# MacBook Pro 14" (j413) audio configuration
# Sets internal mic as default source instead of headset jack
{ ... }: {
  services.pipewire.wireplumber.extraConfig."50-asahi-mic-default" = {
    "wireplumber.settings" = {
      "default.audio.source" = "effect_output.j413-mic";
    };
  };
}
