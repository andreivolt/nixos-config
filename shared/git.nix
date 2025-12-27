{pkgs, ...}: {
  home-manager.sharedModules = [
    {
      programs.git = {
        enable = true;

        signing = {
          key = "36D6CB5336F68AC5";
          signByDefault = true;
        };

        lfs.enable = true;

        ignores = [
          "**/.claude/settings.local.json"
          ".claude/settings.local.json"
          ".DS_Store"
          ".env"
          ".envrc"
          ".nrepl-history"
          ".rebel_readline_history"
          ".yarn"
          "__pycache__"
          "node_modules"
          "Session.vim"
          ".direnv/"
        ];

        attributes = [
          "*.rake diff=ruby"
          "*.rb diff=ruby"
          "*_spec.rb diff=rspec"
        ];

        settings = {
          user = {
            name = "Andrei Volt";
            email = "andrei@avolt.net";
          };

          alias = {
            ci = "commit";
            co = "checkout";
            dc = "diff --cached";
            di = "diff --word-diff=color";
            st = "status --short";
            amend = "commit --amend --reuse-message=HEAD";
            conflicts = "diff --diff-filter=U --name-only --relative";
            am = "commit --all --amend --no-edit";
            ca = "commit --amend -C HEAD";
            pf = "push -f";
            tree = "!git ls-files | tree --fromfile -a";
            ap = "add --patch";
            l = "log --oneline --abbrev-commit --all --graph --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)%<(14)%ar%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'";
            ups = "!git add --update && git commit --amend --reuse-message HEAD && git push --force";
            lb = "!git reflog show --pretty=format:'%gs ~ %gd' --date=relative | grep 'checkout:' | grep -oE '[^ ]+ ~ .*' | awk -F~ '!seen[$1]++' | awk -F' ~ HEAD@{' '{printf(\"  \\033[33m%s: \\033[37m %s\\033[0m\\n\", substr($2, 1, length($2)-1), $1)}'";
            af = "add --force";
          };

          gpg.program = "gpg2";
          tag.gpgSign = true;

          credential = {
            "https://github.com".helper = "!gh auth git-credential";
            "https://gist.github.com".helper = "!gh auth git-credential";
          };

          core = {
            untrackedCache = true;
          };

          init = {
            defaultBranch = "main";
            templateDir = "";
          };

          push = {
            default = "current";
            autoSetupRemote = true;
          };

          pull.rebase = true;

          branch = {
            autoSetupRebase = "remote";
            autoSetupMerge = true;
          };

          rebase.autoStash = true;

          merge = {
            conflictstyle = "diff3";
            tool = "nvim -d";
          };

          diff.tool = "difftastic";
          difftool.prompt = false;
          "difftool \"difftastic\"".cmd = "difft \"$LOCAL\" \"$REMOTE\"";

          pager.difftool = true;

          gc = {
            pruneExpire = "never";
            reflogExpire = "never";
            autodetach = false;
          };

          maintenance = {
            auto = 1;
            strategy = "incremental";
          };

          advice.addIgnoredFile = false;
        };
      };
    }
  ];
}
