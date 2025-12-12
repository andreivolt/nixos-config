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
          version = "1";
        };
      };
    }
  ];
}
