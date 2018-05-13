{ config, pkgs, ... }:

let makeEmacsDaemon = import ../util/make-emacs-daemon.nix; in {
  systemd.user.services.todoEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "todo"; };
}
