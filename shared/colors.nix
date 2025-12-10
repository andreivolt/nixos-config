# Aurora color scheme - single source of truth
# Import and reference: (import ./colors.nix).aurora.normal.red
{
  aurora = {
    background = "#000000";
    foreground = "#ffffff";
    cursor = "#ddd0f4";
    cursorText = "#211c2f";

    selection = {
      background = "#3f4060";
      foreground = "#e7d3fb";
    };

    normal = {
      black = "#070510";
      red = "#ff5874";
      green = "#addb67";
      yellow = "#ffcb65";
      blue = "#be9af7";
      magenta = "#FD9720";
      cyan = "#A1EFE4";
      white = "#645775";
    };

    bright = {
      black = "#443d60";
      red = "#ec5f67";
      green = "#d7ffaf";
      yellow = "#fbec9f";
      blue = "#6690c4";
      magenta = "#ffbe00";
      cyan = "#54CED6";
      white = "#e7d3fb";
    };

    # Extended palette (16-17)
    extended = {
      color16 = "#8a6e2b";
      color17 = "#a8834a";
    };
  };

  # UI colors for rofi, etc.
  ui = {
    bg = "#000000dd";
    bgAlt = "#333333";
    fg = "#cccccc";
    fgDim = "#888888";
  };
}
