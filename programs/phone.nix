{ pkgs, ... }:

let
  phonecall = with pkgs; stdenv.mkDerivation rec {
    name = "phonecall";

    src = [(pkgs.writeScript name ''
      #!/usr/bin/env bash

      # termux-telephony-call $(termux-contacts-list | jq '.[] | select (.name | contains(\"$1\")) | .number')"
      ssh 192.168.1.19 -p 8022 "
        termux-telephony-call $1"
    '')];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
    '';
  };

  sms = with pkgs; stdenv.mkDerivation rec {
    name = "sms";

    src = [(pkgs.writeScript name ''
      #!/usr/bin/env bash

      ssh 192.168.1.19 -p 8022 "
        termux-sms-send $1 '$*'"
    '')];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
    '';
  };

in {
  environment.systemPackages = with pkgs; [
    phonecall
    sms
  ];
}
