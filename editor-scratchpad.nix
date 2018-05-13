{ config, pkgs, ... }:

let makeEmacsDaemon = import ./make-emacs-daemon.nix; in {
  systemd.user.services.editorEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "editor-scratchpad"; };
}
