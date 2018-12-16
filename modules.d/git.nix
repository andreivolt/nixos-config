{ lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [ git ];

  environment.etc."gitconfig".text = let
    global-exclude-patterns = let
      emacs = [ "*~" "\\#*#" "\\.#*" ];
    in
      emacs;
  in with pkgs; generators.toINI {} {
    user = with import /home/avo/lib/credentials.nix; { inherit name; email = email.address; };
    alias = {
      am = "commit --all --amend --no-edit";
      ap = "add --patch";
      ci = "commit";
      co = "checkout";
      dc = "diff --cached";
      di = "diff";
      st = "status --short"; };
    core.pager = "${gitAndTools.diff-so-fancy}/bin/diff-so-fancy | ${wrapped.less}/bin/less -X";
    core.excludesFile = "${writeText "_" (concatStringsSep "\n" global-exclude-patterns)}";
    push.default = "current";
  };
}
