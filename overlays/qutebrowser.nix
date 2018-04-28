self: pkgs: rec {

qutebrowser = pkgs.stdenv.lib.overrideDerivation pkgs.qutebrowser (attrs: rec {
  postInstall = attrs.postInstall + ''
    ln -s $out/share/qutebrowser/scripts/open_url_in_instance.sh $out/bin/qutebrowser-open-in-instance
  '';
});

}
