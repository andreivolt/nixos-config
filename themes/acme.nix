let
  canyonTan   = "bf9f73";
  duneBeige   = "bda78f";
  grottoBlue  = "3c5262";
  mossGreen   = "475451";
  regalBlue   = "4a5070";
  seagullGray = "a3a090";
  steelGray   = "686f82";
  valleyGreen = "6F8568";

  black          = "#000000";
  darkGray       = "#222222";
  gray           = "#444444";
  lightGray      = "#555555";
  lighterGray    = "#b9b9b9";
  lightestGray   = "#eeeeee";
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

  background   = lightestYellow; foreground   = darkGray;

  backgroundContrast = lightestGray;

  subtleHighlight = lightYellow;
  foregroundSecondary = gray;
  foregroundUnimportant = lighterGray;

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
