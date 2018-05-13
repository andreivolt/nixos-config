{ config, pkgs, ... }:

let makeEmacsDaemon = import ./make-emacs-daemon.nix; in {
  systemd.user.services.todoEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "todo"; };
}
