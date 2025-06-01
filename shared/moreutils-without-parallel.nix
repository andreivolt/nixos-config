{
  nixpkgs.overlays = [
    (self: super: {
      moreutilsWithoutParallel = super.moreutils.overrideAttrs (oldAttrs: {
        postInstall = ''
          ${oldAttrs.postInstall or ""}
          rm -f $out/bin/parallel $out/share/man/man1/parallel.1
        '';
      });
    })
  ];
}
