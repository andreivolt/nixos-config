{ config, lib, pkgs, ... }:

{
  # systemd.user.services.ircEmacsDaemon = let
  #   makeEmacsDaemon = import ../util/make-emacs-daemon.nix;
  #   credentials = import ../private/credentials.nix;
  # in
  #   (makeEmacsDaemon { name = "irc"; inherit config pkgs; })
  #   // {
  #     environment.FREENODE_USERNAME = credentials.freenode.username;
  #     environment.FREENODE_PASSWORD = credentials.freenode.password;
  #   };
}
