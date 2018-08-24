{ config, lib, pkgs, ... }:

{
  programs.adb.enable = true;

  users.users.avo.extraGroups = [ "adbusers" ];

  environment.systemPackages = let
    adb-wifi-connect = pkgs.stdenv.mkDerivation rec {
      name = "adb-wifi-connect";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        ${pkgs.androidenv.platformTools}/bin/adb tcpip 5555

        ${pkgs.androidenv.platformTools}/bin/adb connect 192.168.1.11
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [
    adb-wifi-connect
  ];

  home-manager.users.avo
    .home.sessionVariables.ANDROID_SDK_HOME = with config.home-manager.users.avo;
      "${xdg.configHome}/android";

  home-manager.users.avo
    .xdg.configFile = with (import ../private/credentials.nix).adb; {
      "android/adbkey".text = private;
      "android/adbkey.pub".text = public;
    };
}
