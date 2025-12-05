{
  home-manager.sharedModules = [
    {
      home.file.".ignore".text = ''
        *.git
        .DS_Store
        /.bun/install/cache
        /.bundle/cache
        /.cache
        /.cargo/registry
        /.docker/buildx
        /.gitlibs
        /.local
        /.nix-defexpr
        /.nix-profile
        /.npm
        /.vscode
        /Library
        /OrbStack
        /Pictures
        node_modules
      '';
    }
  ];
}
