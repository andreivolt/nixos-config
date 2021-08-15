rec {
  background = "#000000"; foreground = "#cccccc";

  dark = rec {
    urgent = {
      background = "#f0c674";
      foreground = background;
    };
    inactive = {
      background = "#000000";
      foreground = "#cccccc";
    };
    active = {
      background = "#aaaaaa";
      foreground = background;
    };
  };

  white_bg = "#707880"; white_fg = "#aaaaaa";
  black_bg = "#131313"; black_fg = "#373b41";

  blue_fg = "#0000ff"; blue_bg = "#81a2be";
  cyan_fg = "#5e8d87"; cyan_bg = "#8abeb7";
  green_fg = "#00ff00"; green_bg = "#3ec97d";
  red_fg = "#ff0000"; red_bg = "#c94e3e";
  yellow_fg = "#00ffff"; yellow_bg = "#f0c674";
  magenta_fg = "#85678f"; magenta_bg = "#b294bb";

  success = green_fg; warning = yellow_fg; error = red_fg;
  highlight_fg = blue_fg; highlight_bg = blue_bg;
  selection = white_fg;
}
