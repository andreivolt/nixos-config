let
  theme = import ../challenger-deep-theme.nix;
  monospaceFont = "Source Code Pro";
  fontSize = 10;

in {
  config = {
    background_opacity = 0.93;
    colors = {
      bright = {
        black = theme.gray;
        blue = theme.lightBlue;
        cyan = theme.lightCyan;
        green = theme.lightGreen;
        grey = theme.lightGray;
        magenta = theme.lightMagenta;
        red = theme.lightRed;
        white = theme.white;
        yellow = theme.lightYellow;
      };
      cursor = {
        cursor = theme.white;
        text = theme.white;
      };
      normal = {
        black = theme.black;
        blue = theme.blue;
        cyan = theme.cyan;
        green = theme.green;
        grey = theme.gray;
        magenta = theme.magenta;
        red = theme.red;
        white = theme.white;
        yellow = theme.yellow;
      };
      primary = {
        background = theme.background;
        foreground = theme.foreground;
      };
    };
    custom_cursor_colors = true;
    dpi = { x = 96; y = 96; };
    draw_bold_text_with_bright_colors = true;
    font = {
      size = fontSize;
      normal = { family = monospaceFont; style = "Regular"; };
      bold = { family = monospaceFont; style = "Bold"; };
      italic = { family = monospaceFont; style = "Italic"; };
      offset = { x = 0; y = -2; };
      glyph_offset = { x = 0; y = 0; };
    };
    hide_cursor_when_typing = false;
    key_bindings = [
      { action = "Paste";            key = "V";        mods = "Control|Shift"; }
      { action = "Copy";             key = "C";        mods = "Control|Shift"; }
      { action = "Quit";             key = "Q";        mods = "Command"; }
      { action = "Quit";             key = "W";        mods = "Command"; }
      { action = "Paste";            key = "Insert";   mods = "Shift"; }
      { action = "ResetFontSize";    key = "Key0";     mods = "Control"; }
      { action = "IncreaseFontSize"; key = "Equals";   mods = "Control"; }
      { action = "DecreaseFontSize"; key = "Subtract"; mods = "Control"; }
    ];
    selection = {
      semantic_escape_chars = ";│`|:\"' ()[]{}<>";
    };
    tabspaces = 4;
    visual_bell = {
      duration = 0;
    };
    window = {
      dimensions = { columns = 0; lines = 0; };
      padding = { x = 28; y = 20; };
    };
  };
}

