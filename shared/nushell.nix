{
  home-manager.sharedModules = [
    {
      programs.nushell.enable = true;

      xdg.configFile = {
        "nushell/config.nu".source = ./nushell/config.nu;
        "nushell/env.nu".source = ./nushell/env.nu;
      };
    }
  ];
}
