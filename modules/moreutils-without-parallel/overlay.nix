{ lib, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      moreutilsWithoutParallel = lib.overrideDerivation super.moreutils (attrs: {
        postInstall = attrs.postInstall + "\n"
          + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
      });
    })
  ];
}
