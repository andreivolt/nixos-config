{
  home-manager.sharedModules = [
    {
      home.file.".cargo/config.toml".text = ''
        [target.aarch64-linux-android]
        linker = "aarch64-linux-android-clang-wrapper"
      '';
    }
  ];
}
