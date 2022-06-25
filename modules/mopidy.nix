{ pkgs, ... }:

{
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-local
      mopidy-mpd
      mopidy-mpris
      mopidy-scrobbler
      mopidy-spotify
    ];
    configuration = ''
      [audio]
      output = pulsesink server=127.0.0.1:4713

      [spotify]
      enabled = true
      username = builtins.getEnv "SPOTIFY_USERNAME";
      password = builtins.getEnv "SPOTIFY_PASSWORD";
      client_id = builtins.getEnv "SPOTIFY_CLIENT_ID";
      client_secret = builtins.getEnv "SPOTIFY_CLIENT_SECRET";
      bitrate = 320

      [mopify]
      enabled = true
      debug = true

      [local]
      media_dir = /home/avo/gdrive/music
    '';
  };
}
