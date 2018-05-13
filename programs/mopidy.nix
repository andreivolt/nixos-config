{ lib, pkgs, ... }:

{
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [ mopidy-gmusic ];
    configuration = lib.generators.toINI {} {
      gmusic = with (import ../private/credentials.nix).googleAccount; {
        deviceid = "0123456789abcdef";
        username = address;
        password = password;
        bitrate = 320;
      };
    };
  };
}
