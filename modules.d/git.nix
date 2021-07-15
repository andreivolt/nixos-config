{ config, lib, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    home.file.".gitconfig".text = lib.generators.toINI {} {
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
      };
      core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -X";
      push.default = "current";
      hub.oauthtoken = builtins.getEnv "GITHUB_TOKEN";
    };
  };
}
