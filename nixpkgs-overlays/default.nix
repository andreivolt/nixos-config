self: super:

wsta = stdenv.mkDerivation rec {
  name = "wsta-${version}";
  version = "0.5.0";

  src = fetchurl {
      url = "https://github.com/esphen/wsta/releases/download/${version}/wsta-${version}-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "0csvkwyv60smpyqlr6wvn6lmgsi4bpw2iyw1ggz38nwplrgabbrj";
  };

  dontStrip = true;

  buildInputs = [ openssl ] ;

  sourceRoot = ".";

  installPhase = ''
    patchelf --interpreter $(cat $NIX_CC/nix-support/dynamic-linker) --set-rpath ${stdenv.lib.makeLibraryPath [ openssl ]} wsta
    mkdir -p $out/bin
    mv wsta $out/bin
  '';
}
