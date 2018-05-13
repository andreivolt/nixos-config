{ config, lib, pkgs, ... }:

let
  parallel = pkgs.stdenv.lib.overrideDerivation
               pkgs.parallel
               (attrs: { nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.perlPackages.DBDSQLite ];});

in {
  environment.systemPackages = [ parallel ];

  home-manager.users.avo
    .home.sessionVariables.PARALLEL_HOME = with config.home-manager.users.avo;
      "${xdg.cacheHome}/parallel";
}
