let
  black          = "#000000";
  darkGray       = "#101010";
  gray           = "#303030";
  lightGray      = "#505050";
  lightestGray   = "#cccccc";
  cyan           = "#aeeeee";
  yellow         = "#cccc7c";
  lightBlue      = "#eaffff";
  lightYellow    = "#fcfcce";
  lighterYellow  = "#ffffca";
  lightestYellow = "#ffffea";
  turquoise = "#1abc9c";

  red = "#b34747"; lightRed = "#e67373";

in {
  inherit darkGray gray lightGray;

  background   = lightestYellow; foreground   = gray;

  subtleHighlight = lightYellow;
  foregroundFaded = lightestGray;

  highlight = turquoise;

  black        = yellow;         lightBlack   = lightYellow;

  white        = black;          lightWhite   = darkGray;

  blue         = gray;           lightBlue    = lightGray;
  cyan         = gray;           lightCyan    = lightGray;
  magenta      = gray;           lightMagenta = lightGray;

  selection = cyan;
  backgroundFaded = lightestYellow;
  important = "#67809f";

  green        = black;          lightGreen   = darkGray;
  red          = red;            lightRed     = lightRed;
  yellow       = yellow;         lightYellow  = lightYellow;

  light = {
    gray = "#e8e8e8";
  };
}
