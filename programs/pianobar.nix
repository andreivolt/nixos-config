{
  home-manager.users.avo.programs.pianobar = {
    enable = true;

    config =
      with (import ../private/credentials.nix).pandora; { inherit username password; }
      // {
        audio_quality = "high";
      };
  };
}
