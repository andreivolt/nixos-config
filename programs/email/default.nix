{ config, lib, pkgs, myName, myEmail, ... }:

let
  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";
  makeEmacsDaemon = import ../../util/make-emacs-daemon.nix;

in {
  imports = [
    ./msmtp.nix
    ./notmuch.nix
    ./offlineimap.nix
    ./mailcap.nix
  ];

  environment.systemPackages = (with pkgs; [
    isync # https://wiki.archlinux.org/index.php/Isync https://gist.github.com/au/a271c09e8233f19ffb01da7f017c7269 https://github.com/kzar/davemail
    mailutils
    procmail
  ]);

  systemd.user.services.mailEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "mail"; };
}
