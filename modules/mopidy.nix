{ pkgs, ... }:

{
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-local
      mopidy-mpd
      mopidy-mpris
      mopidy-scrobbler
    ];
    configuration = ''
      [audio]
      output = pulsesink server=127.0.0.1:4713

      [mopify]
      enabled = true
      debug = true

      [local]
      media_dir = /home/avo/gdrive/music
    '';
  };

  # TODO
  # homebrew.taps = [ "mopidy/mopidy" ];
  # homebrew.extraConfig = ''
  #   # brew "mopidy/mopidy/mopidy", args: ["HEAD"]
  # '';
}
