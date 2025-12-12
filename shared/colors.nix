# Obsidian Aurora color scheme - single source of truth
# Import and reference: (import ./colors.nix).aurora.normal.red
{
  # Accent colors - clear muted red
  accent = {
    primary = "#b85555";      # Muted red - main accent
    secondary = "#994848";    # Darker red - subtle use
    dim = "#6a3a3a";          # Dark red - inactive states
    bright = "#d07070";       # Light red - highlights/hover
  };

  # UI chrome - refined grays with warmth
  ui = {
    bg = "#0a0a0aee";         # Near-black with slight warmth
    bgAlt = "#1a1816";        # Dark warm gray
    bgElevated = "#252220";   # Elevated surfaces
    fg = "#d4d0ca";           # Warm off-white (not pure white)
    fgDim = "#7a756d";        # Muted warm gray
    fgMuted = "#4a4540";      # Very dim (timestamps, etc.)
    border = "#2a2622";       # Subtle warm border
  };

  # Aurora terminal palette - preserved for syntax highlighting
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
}
