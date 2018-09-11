{
  dark = rec {
    background = black; foreground = "#cccccc";

    black = "#111111"; white = "#c8c8c8";

    lightWhite = "#1f1f1f";
    lightBlack = "#777777";

    blue = "#217dd9"; lightBlue = "#0b2c4d";
    cyan = "#aeeeee"; lightCyan = "#aeeeee";
    green = "#45e67a"; lightGreen = "#45e67a";
    red = "#ff4d4d"; lightRed = "#ff4d4d";
    yellow = "#d9b500"; lightYellow = "#cccca7";
    magenta = "#b045e6"; lightMagenta = "#b045e6";

    error = red;
    success = green;
    warning = yellow;

    highlight = blue;
    selection = lightWhite;

    color0 = black; color8 = lightBlack;
    color1 = red; color9 = lightRed;
    color2 = green; color10 = lightGreen;
    color3 = yellow; color11 = lightYellow;
    color4 = blue; color12 = lightBlue;
    color5 = magenta; color13 = lightMagenta;
    color6 = cyan; color14 = lightCyan;
    color7 = white; color15 = lightWhite; };

  light = let colors = {
    lightWhite = "#eeeeee";
    black = "#111111";
    gray = "#444444";
    white = "#cccccc";

    blue = "#217dd9"; };
  in rec {
    background = colors.lightWhite; backgroundFaded = colors.white;
    foreground = colors.black; foregroundFaded = colors.gray;


    black = background; lightBlack = foregroundFaded;
    white = foreground; lightWhite = backgroundFaded;

    blue = colors.blue; lightBlue = colors.blue;
    cyan = foreground; lightCyan = foreground;
    green = foreground; lightGreen = foreground;
    magenta = foreground; lightMagenta = foreground;
    red = foreground; lightRed = foreground;
    yellow = foreground; lightYellow = foreground;

    error = red; success = green; warning = yellow;

    highlight = blue;
    selection = lightWhite;

    color0 = background; color8 = backgroundFaded;
    color1 = red; color9 = lightRed;
    color2 = green; color10 = lightGreen;
    color3 = yellow; color11 = lightYellow;
    color4 = blue; color12 = lightBlue;
    color5 = magenta; color13 = lightMagenta;
    color6 = cyan; color14 = lightCyan;
    color7 = foreground; color15 = foregroundFaded; };
}
