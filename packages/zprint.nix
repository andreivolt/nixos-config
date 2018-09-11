self: super: with super; {

zprint = stdenv.mkDerivation rec {
  name = "zprint";

  src = fetchurl {
    url = "https://github.com/kkinnear/zprint/releases/download/0.4.10/zprintl-0.4.10";
    sha256 = "0iab2gvynb0njhr2vy26li165sc2v6p5pld7ifp6jlf7yj3yr4gl";
  };
  unpackPhase = "true";

  dontStrip = true;
  preFixup = let libPath = lib.makeLibraryPath [ zlib ]; in ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      $out/bin/zprint'';
  installPhase = "mkdir -p $out/bin && cp $src $out/bin/zprint && chmod +x $out/bin/zprint";
};

}
