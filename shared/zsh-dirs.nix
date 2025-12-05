{
  home-manager.sharedModules = [
    {
      home.activation.createZshDirs = ''
        mkdir -p ~/.cache/zsh
        mkdir -p ~/.local/share/zsh
        mkdir -p ~/.local/state/zsh
      '';
    }
  ];
}
