{ lib
, stdenvNoCC
, iosevka
, nerd-font-patcher
}:

let
  # Build Pragmasevka from Iosevka source with custom build plan
  pragmasevka-base = iosevka.override {
    set = "Pragmasevka";
    privateBuildPlan = {
      family = "Pragmasevka";
      spacing = "term";
      serifs = "sans";
      noCvSs = true;
      exportGlyphNames = true;

      widths.normal = {
        shape = 500;
        menu = 5;
        css = "normal";
      };

      metricOverride = {
        leading = 1100;
        xHeight = 550;
      };

      ligations = {
        inherits = "default-calt";
        enables = [
          "eqslasheq"
          "kern-dotty"
          "kern-bars"
          "llggeq"
          "trig"
        ];
        disables = [ "slash-asterisk" ];
      };

      variants.inherits = "ss08";

      weights = {
        light = {
          shape = 300;
          menu = 300;
          css = 300;
        };
        regular = {
          shape = 425;
          menu = 400;
          css = 400;
        };
        semibold = {
          shape = 600;
          menu = 600;
          css = 600;
        };
        bold = {
          shape = 800;
          menu = 700;
          css = 700;
        };
      };

      slopes = {
        upright = "default.Upright";
        italic = "default.Italic";
      };
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "pragmasevka-nerd-font";
  version = pragmasevka-base.version;

  src = pragmasevka-base;

  nativeBuildInputs = [ nerd-font-patcher ];

  buildPhase = ''
    runHook preBuild
    mkdir -p patched
    for font in $src/share/fonts/truetype/*.ttf; do
      nerd-font-patcher --complete --careful -out patched "$font"
    done
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    install -m644 patched/*.ttf $out/share/fonts/truetype/
    runHook postInstall
  '';

  requiredSystemFeatures = [ "big-parallel" ];

  meta = {
    description = "Pragmata Pro doppelgänger made of Iosevka SS08 with Nerd Font glyphs";
    homepage = "https://github.com/shytikov/pragmasevka";
    license = lib.licenses.ofl;
  };
}
