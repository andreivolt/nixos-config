let credentials = import ../credentials.nix;
in {
  config =
    with credentials.pandora; {inherit username password;} // {
      audio_quality = "high";
    };
}
