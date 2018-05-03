let
  black          = "#000000";
  darkGray       = "#101010";
  mediumGray     = "#303030";
  lightGray      = "#505050";
  cyan           = "#aeeeee";
  yellow         = "#cccc7c";
  lightBlue      = "#eaffff";
  lightYellow    = "#fcfcce";
  lighterYellow  = "#ffffca";
  lightestYellow = "#ffffea";

in {
  background   = lightestYellow; foreground   = black;

  black        = yellow;         lightBlack   = lightYellow;

  darkGray     = lightYellow;    gray         = lightYellow;
  lightGray    = lightestYellow; lightestGray = lighterYellow;

  white        = black;          lightWhite   = darkGray;

  blue         = black;          lightBlue    = darkGray;
  cyan         = black;          lightCyan    = darkGray;
  green        = black;          lightGreen   = darkGray;
  magenta      = black;          lightMagenta = darkGray;
  red          = black;          lightRed     = darkGray;
  yellow       = black;          lightYellow  = darkGray;

  light = {
    gray = "#e8e8e8";
  };
}
