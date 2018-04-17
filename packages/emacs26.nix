{ stdenv, fetchgit, emacs25, lib, pkgs }:

stdenv.lib.overrideDerivation
  (emacs25.override { srcRepo = true; }) (attrs: rec {
    name = "emacs-${version}${versionModifier}";
    version = "26.0";
    versionModifier = ".90";

    buildInputs = emacs25.buildInputs ++
      [ pkgs.git pkgs.libpng.dev pkgs.libjpeg.dev pkgs.libungif pkgs.libtiff.dev pkgs.librsvg.dev pkgs.imagemagick.dev];

    patches = lib.optionals stdenv.isDarwin
      [ ./emacs/patches/at-fdcwd.patch
        ./emacs/patches/emacs-26.patch ];

    CFLAGS = "-Ofast -momit-leaf-frame-pointer -DMAC_OS_X_VERSION_MAX_ALLOWED=101200";

    src = fetchgit {
      url = https://git.savannah.gnu.org/git/emacs.git;
      rev = "aa40014ba373ac633b118dc63647f323ef0cedb5";
      sha256 = "1asv0m76phm9hm22wnknsrkp1hgxw5cmm8fk2d2iyar9mcw29c0n";
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
  })
