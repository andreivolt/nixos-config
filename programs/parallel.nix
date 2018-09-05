{ config, lib, pkgs, ... }:

{
  environment.systemPackages = let
    parallel = with pkgs;
      stdenv.lib.overrideDerivation
        pkgs.parallel
        (attrs: { nativeBuildInputs = attrs.nativeBuildInputs ++ [ perlPackages.DBDSQLite ];});
  in [ parallel ];

  environment.variables.PARALLEL_HOME = "~/.cache/parallel";
}
