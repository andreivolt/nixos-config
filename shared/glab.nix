{
  home-manager.sharedModules = [
    {
      xdg.configFile."glab-cli/aliases.yml".text = ''
        ci: pipeline ci
        co: mr checkout
      '';
    }
  ];
}
