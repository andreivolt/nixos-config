{
  home-manager.sharedModules = [
    {
      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = false; # already configured in git.nix
        settings = {
          aliases = {
            co = "pr checkout";
          };
          git_protocol = "https";
          version = "1";
        };
        hosts = {
          "github.com" = {
            git_protocol = "https";
            user = "andreivolt";
          };
        };
      };
    }
  ];
}
