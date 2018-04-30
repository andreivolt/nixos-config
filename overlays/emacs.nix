self: pkgs: rec {

emacs26 = with pkgs; stdenv.lib.overrideDerivation
  (emacs25.override { srcRepo = true; }) (attrs: rec {
  name = "emacs-${version}${versionModifier}";
  version = "26.0";
  versionModifier = ".90";

  buildInputs = emacs25.buildInputs ++
    [ git libpng.dev libjpeg.dev libungif libtiff.dev librsvg.dev
      imagemagick.dev ];

  patches = lib.optionals stdenv.isDarwin
    [ ./emacs/patches/at-fdcwd.patch
      ./emacs/patches/emacs-26.patch ];

  CFLAGS = "-Ofast -momit-leaf-frame-pointer -DMAC_OS_X_VERSION_MAX_ALLOWED=101200";

  src = fetchgit {
    url = https://git.savannah.gnu.org/git/emacs.git;
    rev = "d6e2c593180934926fa4cc5b58fdab82b20f5f14";
    sha256 = "00vlkwavipymg802f54aj9xp7d8wm4pngjy9r6f32mp26v2smick";
  };

  postPatch = ''
    rm -fr .git
  '';

  postInstall = ''
    mkdir -p $out/share/emacs/site-lisp
    rm -rf $out/var
    rm -rf $out/share/emacs/${version}/site-lisp
    for srcdir in src lisp lwlib ; do
      dstdir=$out/share/emacs/${version}/$srcdir
      mkdir -p $dstdir
      find $srcdir -name "*.[chm]" -exec cp {} $dstdir \;
      cp $srcdir/TAGS $dstdir
      echo '((nil . ((tags-file-name . "TAGS"))))' > $dstdir/.dir-locals.el
    done
  '' + lib.optionalString stdenv.isDarwin ''
    mkdir -p $out/Applications
    mv nextstep/Emacs.app $out/Applications
  '';
});

}
