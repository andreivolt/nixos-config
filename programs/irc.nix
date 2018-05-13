{ config, lib, pkgs, ... }:

{
  services.bitlbee = {
    enable = true;
    libpurple_plugins = with pkgs; [ telegram-purple ];
  };

  environment.systemPackages = with pkgs; [ weechat ];

  systemd.user.services.ircEmacsDaemon = let
    makeEmacsDaemon = import ../util/make-emacs-daemon.nix;
    credentials = import ../private/credentials.nix;
  in
    (makeEmacsDaemon { name = "irc"; inherit config pkgs; })
    // {
      environment.FREENODE_USERNAME = credentials.freenode.username;
      environment.FREENODE_PASSWORD = credentials.freenode.password;
    };
}
