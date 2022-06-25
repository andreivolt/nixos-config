{ lib, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      moreutils = super.moreutils.overrideAttrs (attrs: {
        postInstall = attrs.postInstall + "\n"
          + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
      });
    })
  ];
}
