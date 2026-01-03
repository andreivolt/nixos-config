{ colors }:
let
  aurora = colors.aurora;
  accent = colors.accent;
  ui = colors.ui;
in {
  # Aurora terminal colors with Obsidian Aurora chrome
  background = aurora.background;
  foreground = aurora.foreground;
  selection_background = aurora.selection.background;
  selection_foreground = aurora.selection.foreground;
  url_color = aurora.normal.cyan;
  url_style = "straight";
  cursor = aurora.cursor;
  cursor_text_color = aurora.cursorText;
  active_border_color = accent.primary;
  inactive_border_color = ui.border;
  active_tab_background = ui.bgAlt;
  active_tab_foreground = accent.primary;
  inactive_tab_background = aurora.background;
  inactive_tab_foreground = ui.fgDim;
  tab_bar_background = aurora.background;

  color0 = aurora.normal.black;
  color1 = aurora.normal.red;
  color2 = aurora.normal.green;
  color3 = aurora.normal.yellow;
  color4 = aurora.normal.blue;
  color5 = aurora.normal.magenta;
  color6 = aurora.normal.cyan;
  color7 = aurora.normal.white;
  color8 = aurora.bright.black;
  color9 = aurora.bright.red;
  color10 = aurora.bright.green;
  color11 = aurora.bright.yellow;
  color12 = aurora.bright.blue;
  color13 = aurora.bright.magenta;
  color14 = aurora.bright.cyan;
  color15 = aurora.bright.white;
  color16 = aurora.extended.color16;
  color17 = aurora.extended.color17;
}
