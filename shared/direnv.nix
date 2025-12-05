{
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;
  homeDir =
    if isDarwin
    then "/Users/andrei"
    else "/home/andrei";
in {
  home-manager.sharedModules = [
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
        config = {
          global = {
            load_dotenv = true;
          };
          whitelist = {
            prefix = ["${homeDir}/dev"];
          };
        };
      };
    }
  ];
}
