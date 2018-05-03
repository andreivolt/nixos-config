self: pkgs: rec {

url-parser = with pkgs; stdenv.mkDerivation rec {
  name = "url-parser-${version}";
  version = "1.0.0-beta4";

  src = fetchurl {
    url = "https://github.com/herloct/url-parser/releases/download/${version}/url-parser-Linux-x86_64";
    sha256 = "1kggw2qwx8r9jv1g0fq7lpzk4agab5va2swhhq7yqfpad2kyzf39";
  };

  sourceRoot = ".";

  unpackPhase = "true";

  installPhase = ''
    cp $src url-parser
    chmod +x url-parser
    mkdir -p $out/bin; mv url-parser $out/bin
  '';
};

}
