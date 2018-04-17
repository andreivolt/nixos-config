self: pkgs: rec {

emacs26 = with pkgs; stdenv.lib.overrideDerivation
  (emacs25.override { srcRepo = true; }) (attrs: rec {
  name = "emacs-${version}${versionModifier}";
  version = "26.1";
  versionModifier = "rc-1";

  buildInputs = emacs25.buildInputs ++
    [ git libpng.dev libjpeg.dev libungif libtiff.dev librsvg.dev
      imagemagick.dev ];

  CFLAGS = "-Ofast -momit-leaf-frame-pointer -DMAC_OS_X_VERSION_MAX_ALLOWED=101200";

  src = fetchgit {
    url = https://git.savannah.gnu.org/git/emacs.git;
    rev = "c267421647510319d2a70554e42f0d1c394dba0a";
    sha256 = "1asv0m76phm9hm22wnknsrkp1hgxw5cmm8fk2d2iyar9mcw29c0n";
  };
});

}
