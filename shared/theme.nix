rec {
  background = "000000";
  foreground = "ffffff";

  font = {
    family = "Ubuntu";
  };

  dark = {
    urgent = {
      background = "f0c674";
      foreground = background;
    };
    inactive = {
      background = "181818";
      foreground = "aaaaaa";
    };
    active = {
      background = "3c3c3c";
      foreground = foreground;
    };
  };

  colors = {
    primary = {
      background = "0x1b182c";
      foreground = "0xcbe3e7";
    };
    normal = {
      black = "100e23";
      red = "ff8080";
      green = "95ffa4";
      yellow = "ffe9aa";
      blue = "91ddff";
      magenta = "c991e1";
      cyan = "aaffe4";
      white = "cbe3e7";
    };
    bright = {
      black = "565575";
      red = "ff5458";
      green = "62d196";
      yellow = "ffb378";
      blue = "65b2ff";
      magenta = "906cff";
      cyan = "63f2f1";
      white = "a6b3cc";
    };
  };

  white_bg = "707880";
  white_fg = "aaaaaa";
  black_bg = "131313";
  black_fg = "373b41";

  blue_fg = "0000ff";
  blue_bg = "81a2be";
  cyan_fg = "5e8d87";
  cyan_bg = "8abeb7";
  green_fg = "00ff00";
  green_bg = "3ec97d";
  red_fg = "ff0000";
  red_bg = "c94e3e";
  yellow_fg = "00ffff";
  yellow_bg = "f0c674";
  magenta_fg = "85678f";
  magenta_bg = "b294bb";

  success = green_fg;
  warning = yellow_fg;
  error = red_fg;
  selection = white_fg;
}
