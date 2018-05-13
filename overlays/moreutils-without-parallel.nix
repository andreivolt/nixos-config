self: pkgs: rec {

moreutilsWithoutParallel = pkgs.stdenv.lib.overrideDerivation
                             pkgs.moreutils
                             (attrs: { postInstall = attrs.postInstall + "; rm $out/bin/parallel"; });

}
