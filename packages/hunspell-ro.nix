self: super: with super; {

hunspell-ro = let
  dic = (builtins.fetchurl "https://chromium.googlesource.com/chromium/deps/hunspell_dictionaries/+/master/ro_RO.dic?format=TEXT");
  aff = (builtins.fetchurl "https://chromium.googlesource.com/chromium/deps/hunspell_dictionaries/+/master/ro_RO.aff?format=TEXT");
in pkgs.stdenv.mkDerivation {
  name = "hunspell-ro";
  src = []; unpackPhase = "true"; installPhase = ''
    mkdir -p $out/share/hunspell
    base64 --decode ${dic} > $out/share/hunspell/ro.dic
    base64 --decode ${aff} > $out/share/hunspell/ro.aff
  ''; };

}
