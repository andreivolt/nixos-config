{ config, lib, pkgs, ... }:

{
  environment.systemPackages = let
    parallel = with pkgs;
      stdenv.lib.overrideDerivation
        pkgs.parallel
        (attrs: { nativeBuildInputs = attrs.nativeBuildInputs ++ [ perlPackages.DBDSQLite ];});
  in [ parallel ];

  home-manager.users.avo
    .home.sessionVariables.PARALLEL_HOME = with config.home-manager.users.avo;
      "${xdg.cacheHome}/parallel";
}
