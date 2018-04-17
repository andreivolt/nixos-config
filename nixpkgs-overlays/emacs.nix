self: pkgs: rec {

emacs = emacs26;

emacs26 = with pkgs; stdenv.lib.overrideDerivation
  (emacs25.override { srcRepo = true; }) (attrs: rec {
  name = "emacs-${version}${versionModifier}";
  version = "emacs-26.1";
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
  ''
});
