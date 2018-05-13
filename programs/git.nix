{ lib, pkgs, ... }:

let
  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";

in {
  imports = [
    ./ghi.nix
    ./hub.nix
  ];

  environment.systemPackages = with pkgs.gitAndTools; [
    diff-so-fancy
    git
  ];

  home-manager.users.avo
    .programs.git = {
      enable = true;

      userName  = myName; userEmail = myEmail;

      aliases = {
        am   = "commit --amend -C HEAD";
        ap   = "add -p";
        ci   = "commit";
        co   = "checkout";
        dc   = "diff --cached";
        di   = "diff";
        root = "!pwd";
        st   = "status --short";
      };

      extraConfig.core = {
        editor = "${pkgs.emacs}/bin/emacsclient --tty";
        pager  = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -RFX";
      };

      ignores = [
        "*~"
        "tags"
        ".#*"
        ".env*"
        ".nrepl*"
      ];
    };

  home-manager.users.avo
    .programs.zsh.shellAliases = {
      gc = "${pkgs.git}/bin/git clone";
      gr = "cd $(${pkgs.git}/bin/git root)";
    };
}
