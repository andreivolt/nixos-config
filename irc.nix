{ config, lib, pkgs, ... }:

let
  makeEmacsDaemon = import ./make-emacs-daemon.nix;
  credentials = import ./credentials.nix;

in {
  services.bitlbee = {
    enable = true;
    libpurple_plugins = with pkgs; [ telegram-purple ];
  };

  environment.systemPackages = with pkgs; [ weechat ];

  systemd.user.services.ircEmacsDaemon =
    (makeEmacsDaemon { inherit config pkgs; name = "irc"; }) // {
      environment.FREENODE_PASSWORD =
        "'${credentials.freenode_password}'";
    };
}