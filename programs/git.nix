{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs.gitAndTools; [
    diff-so-fancy
    git
  ];

  environment.etc."gitconfig".text = let
    excludes-file = pkgs.writeText "excludes-file" (lib.concatStringsSep "\n" [
      "*~"
      "tags"
      ".#*"
      ".env*"
      ".nrepl*"
    ]);

  in lib.generators.toINI {} {
    user = {
      name = "Andrei Vladescu-Olt";
      email = "andrei@avolt.net";
    };

    alias = {
      am = "commit --amend -C HEAD";
      ap = "add -p";
      ci = "commit";
      co = "checkout";
      dc = "diff --cached";
      di = "diff";
      root = "!pwd";
      st = "status --short";
    };

    core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -RFX";

    core.excludesFile = "${excludes-file}";
  };

  programs.zsh.interactiveShellInit = lib.mkAfter ''
    alias gc='${pkgs.git}/bin/git clone'
    alias gr='cd $(${pkgs.git}/bin/git root)'
  '';
}
