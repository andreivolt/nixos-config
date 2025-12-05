{pkgs, ...}: let
  homeDir = if pkgs.stdenv.isDarwin then "/Users/andrei" else "/home/andrei";
in {
  home-manager.sharedModules = [
    {
      home.file.".npmrc".text = ''
        prefix=${homeDir}/.local
      '';
    }
  ];
}
