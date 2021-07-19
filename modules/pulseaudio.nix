{
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.extraModules = [
    pkgs.pulseaudio-modules-bt
  ];
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.daemon.config = {
    flat-volumes = "no";
    resample-method = "soxr-vhq";
    avoid-resampling = "yes";
    default-sample-format = "s32le";
    default-sample-rate = "96000";
  };
}
