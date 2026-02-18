let
  fontSizePx = 14;
in {
  inherit fontSizePx;
  fontSizePt = builtins.ceil (fontSizePx * 0.75);
  fontFamily = "Inter";
}
