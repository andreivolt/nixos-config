{ config, lib, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    home.file.".gitconfig".text = lib.generators.toINI { } {
      user.name = "Andrei Volt";
      user.email = "andrei@avolt.net";
      alias = {
        am = "commit --all --amend --no-edit";
        ap = "add --patch";
        ci = "commit";
        co = "checkout";
        dc = "diff --cached";
        di = "diff";
        st = "status --short";
        ups =
          "!git add --update && git commit --amend --reuse-message HEAD && git push --force";
      };
      # core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -X";
      push.default = "current";
      hub.oauthtoken = builtins.getEnv "GITHUB_TOKEN";

      pager.diff = "${pkgs.delta}/bin/delta";
      pager.log = "${pkgs.delta}/bin/delta";
      pager.reflog = "${pkgs.delta}/bin/delta";
      pager.show = "${pkgs.delta}/bin/delta";

      user.signingkey = "36D6CB5336F68AC5";
      commit.gpgsign = true;

      interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";

      "credential \"https://github.com\"".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };
}
