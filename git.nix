{ lib, pkgs, ... }:

let
  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";

in {
  environment.systemPackages =
    with pkgs.gitAndTools; [
      # haskellPackages.github-backup
      diff-so-fancy
      git
      git-imerge
      hub
      tig
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
        pager = "diff-so-fancy | less --tabs=4 -RFX";
      };

      ghi.token = builtins.getEnv "GHI_TOKEN";
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
        oauth_token = builtins.getEnv "GITHUB_OAUTH_TOKEN";
      };
    };
  };
}
