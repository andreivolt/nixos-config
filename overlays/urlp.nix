self: pkgs: rec {

urlp = with pkgs; stdenv.mkDerivation rec {
  name = "urlp-${version}";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/clayallsopp/urlp/releases/download/${version}/urlp-Linux-x86_64";
    sha256 = "17r6n69pva4df7hk0lckjpwd113c874vd57z0c2kymb2vpx3ryqh";
  };

  sourceRoot = ".";

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/urlp
    chmod +x $out/bin/urlp
  '';
};

}
