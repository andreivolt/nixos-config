{ config, lib, pkgs, myName, myEmail, ... }:

let
  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";
  makeEmacsDaemon = import ../../util/make-emacs-daemon.nix;

in {
  imports = [
    ./msmtp.nix
    ./notmuch.nix
    ./offlineimap.nix
  ];

  environment.systemPackages = with pkgs; let
    email = pkgs.stdenv.mkDerivation rec {
      name = "email";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        ${pkgs.emacs}/bin/emacsclient \
            --socket-name mail \
            --create-frame --frame-parameters '((name . "mail"))' --eval '(+avo/mail)' \
            --no-wait
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [
    isync # https://wiki.archlinux.org/index.php/Isync https://gist.github.com/au/a271c09e8233f19ffb01da7f017c7269 https://github.com/kzar/davemail
    mailutils
    email
  ];

  # systemd.user.services.mailEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "mail"; };

  environment.etc."mailcap".text =  let 
    plaintextify = "${pkgs.libreoffice}/bin/plaintextify < %s; copiousoutput";
    libreoffice = "${pkgs.libreoffice}/bin/libreoffice %s";
  in ''
    application/doc;
    application/msword;                                                        ${plaintextify}
    application/pdf;                                                           ${pkgs.zathura}/bin/zathura %s pdf
    application/vnd.ms-powerpoint;                                             ${libreoffice}
    application/vnd.ms-powerpoint;                                             ${plaintextify}
    application/vnd.openxmlformats-officedocument.presentationml.presentation; ${libreoffice}
    application/vnd.openxmlformats-officedocument.presentationml.presentation; ${plaintextify}
    application/vnd.openxmlformats-officedocument.presentationml.slideshow;    ${libreoffice}
    application/vnd.openxmlformats-officedocument.presentationml.slideshow;    ${plaintextify}
    application/vnd.openxmlformats-officedocument.spreadsheetmleet;            ${plaintextify}
    application/vnd.openxmlformats-officedocument.wordprocessingml.document;   ${plaintextify}
    image;                                                                     ${pkgs.sxiv}/bin/sxiv %s
    text/html;                                                                 ${pkgs.qutebrowser}/bin/qutebrowser-open;
    text/html;                                                                 ${pkgs.w3m}/bin/w3m -o display_link=true -o display_link_number=true -dump -I %{charset} -cols 72 -T text/html %s; nametemplate=%s.html; copiousoutput
  '';
}
