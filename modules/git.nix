{ config, lib, pkgs, ... }:

{
  environment.variables.DELTA_PAGER = "less -R";

  home-manager.users.avo.programs.git = {
    enable = true;
    package = lib.hiPrio pkgs.gitFull; # git-with-svn collision
    aliases = {
      am = "commit --all --amend --no-edit";
      ap = "add --patch";
      ci = "commit";
      co = "checkout";
      dc = "diff --cached";
      di = "diff";
      st = "status --short";
      ups = "!git add --update && git commit --amend --reuse-message HEAD && git push --force";
      l = "log --oneline --abbrev-commit --all --graph --decorate --color";
    };
    signing = {
      key = "36D6CB5336F68AC5";
      signByDefault = true;
    };
    userEmail = "andrei@avolt.net";
    userName = "Andrei Volt";
    delta.enable = true;
    extraConfig = {
      # core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -X";
      push.default = "current";
      hub.oauthtoken = builtins.getEnv "GITHUB_TOKEN";
      # interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
      "credential \"https://github.com\"".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
    ignores = [
      ".nrepl-history"
      ".rebel_readline_history"
    ];
  };

  # home-manager.users.avo = { pkgs, config, ... }: {
  #   home.file.".gitconfig".text = lib.generators.toINI { } {
  #     user.name = "Andrei Volt";
  #     user.email = "andrei@avolt.net";
  #     user.signingkey = "36D6CB5336F68AC5";
  #     commit.gpgsign = true;
  #     core.excludesFile = builtins.toString (pkgs.writeText "gitignore" ''
  #       .nrepl-history
  #     '');
  #     alias = {
  #       am = "commit --all --amend --no-edit";
  #       ap = "add --patch";
  #       ci = "commit";
  #       co = "checkout";
  #       dc = "diff --cached";
  #       di = "diff";
  #       st = "status --short";
  #       ups =
  #         "!git add --update && git commit --amend --reuse-message HEAD && git push --force";
  #     };
  #     # core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -X";
  #     push.default = "current";
  #     hub.oauthtoken = builtins.getEnv "GITHUB_TOKEN";

  #     pager.diff = "${pkgs.delta}/bin/delta";
  #     pager.log = "${pkgs.delta}/bin/delta";
  #     pager.reflog = "${pkgs.delta}/bin/delta";
  #     pager.show = "${pkgs.delta}/bin/delta";

  #     interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";

  #     "credential \"https://github.com\"".helper = "!${pkgs.gh}/bin/gh auth git-credential";
  #   };
  # };
}
