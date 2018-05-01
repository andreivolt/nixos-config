{ lib, pkgs, ... }:

let
  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";
  credentials = import ./credentials.nix;

in {
  environment.systemPackages =
    with pkgs.gitAndTools; [
      diff-so-fancy
      git
      hub
    ];

  home-manager.users.avo.programs.git = {
    enable = true;

    userName  = myName;
    userEmail = myEmail;

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

    extraConfig = {
      core = {
        editor = "emacsclient -nw";
        pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less --tabs=4 -RFX";
      };

      ghi.token = credentials.ghi_token;
    };

    ignores = [
      "*~"
      "tags"
      ".#*"
      ".env*"
      ".nrepl*"
    ];
  };

  home-manager.users.avo.xdg.configFile = {
    "hub".text = lib.generators.toYAML {} {
      "github.com" = {
        user = "andreivolt";
        oauth_token = credentials.github_oauth_token;
      };
    };
  };
}
