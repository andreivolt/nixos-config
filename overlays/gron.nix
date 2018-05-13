self: pkgs: rec {

gron = with pkgs; stdenv.mkDerivation rec {
  name = "gron-${version}";
  version = "0.5.2";

  src = fetchurl {
    url = "https://github.com/tomnomnom/gron/releases/download/v0.5.2/gron-linux-amd64-0.5.2.tgz";
    sha256 = "06f9ygl32zmwcab0vaqms5190lyfgy74lp00qzcmxk0bl7ghi7w1";
  };

  sourceRoot = ".";

  installPhase = ''
    patchelf --interpreter $(cat $NIX_CC/nix-support/dynamic-linker) gron
    mkdir -p $out/bin
    mv gron $out/bin
  '';
};

}
