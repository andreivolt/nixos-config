{ pkgs, ... }:

{
  # hardware.pulseaudio.enable = true;
  # hardware.pulseaudio.extraModules = [
  #   pkgs.pulseaudio-modules-bt
  # ];
  # hardware.pulseaudio.package = pkgs.pulseaudioFull;
  # hardware.pulseaudio.daemon.config = {
  #   flat-volumes = "no";
  #   resample-method = "soxr-vhq";
  #   avoid-resampling = "yes";
  #   default-sample-format = "s32le";
  #   default-sample-rate = "96000";
  # };

# rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
}
