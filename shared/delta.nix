# Delta diff viewer configuration
{ ... }: {
  home-manager.sharedModules = [
    {
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          side-by-side = true;
          line-numbers = false;
        };
      };
    }
  ];
}
