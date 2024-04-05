{ pkgs, ... }:

{
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-iris
      mopidy-local
      mopidy-moped
      mopidy-mopify
      mopidy-mpd
      mopidy-mpris
      mopidy-scrobbler
      mopidy-spotify
    ];
    configuration = ''
      [audio]
      output = pulsesink server=127.0.0.1:4713

      [mopify]
      enabled = true
      debug = true

      [local]
      media_dir = /home/avo/gdrive/music

      [mpd]
      hostname = ::

      [spotify]
      enabled = true
      username = ${getEnv "SPOTIFY_USERNAME"}
      password = ${getEnv "SPOTIFY_PASSWORD"}
      client_id = ${getEnv "SPOTIFY_CLIENT_ID"}
      client_secret = ${getEnv "SPOTIFY_CLIENT_SECRET"}
    '';
  };

  # TODO
  # homebrew.taps = [ "mopidy/mopidy" ];
  # homebrew.extraConfig = ''
  #   # brew "mopidy/mopidy/mopidy", args: ["HEAD"]
  # '';
}
