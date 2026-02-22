let
  fontSizePx = 14;
in {
  inherit fontSizePx;
  fontSizePt = builtins.floor (fontSizePx * 0.75);
  fontFamily = "Inter Tight";
}
