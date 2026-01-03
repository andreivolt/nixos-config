{pkgs, ...}:
let
  aliases = import ./aliases.nix;
in {
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
          ".clj-kondo/"
          ".DS_Store"
          ".env"
          ".envrc"
          ".lsp/"
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

          alias = aliases;

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
