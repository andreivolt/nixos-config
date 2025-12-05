{
  home-manager.sharedModules = [
    {
      xdg.configFile."rustfmt/rustfmt.toml".text = ''
        max_width = 120
        use_small_heuristics = "Max"
      '';
    }
  ];
}
