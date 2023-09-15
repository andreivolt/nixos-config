{ pkgs, ...}:

{
  services.spotifyd.enable = true;
  services.spotifyd.settings = {
    global = {
      username = "116185637";
      password = "2xem@XKB6cJKu64";
      # password_cmd = "command_that_writes_password_to_stdout";
      backend = "pulseaudio";
      bitrate = 320;
    };
  };
  # services.spotifyd.package = pkgs.spotifyd.override {
  #   withPulseAudio = true;
  #   withMpris = true;
  # };
}
