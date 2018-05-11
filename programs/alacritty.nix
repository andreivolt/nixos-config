let
  theme = import ../themes/challenger-deep.nix;
  monospaceFont = "Source Code Pro for Powerline";
  fontSize = 10;

in {
  config = {
    background_opacity = 0.93;
    colors = {
      primary = {
        background = "#000000";
        foreground = theme.foreground;
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
    };
    custom_cursor_colors = true;
    dpi = { x = 180; y = 180; };
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
      { action = "Paste";            mods = "Control|Shift"; key = "V";        }
      { action = "Copy";             mods = "Control|Shift"; key = "C";        }
      { action = "Quit";             mods = "Command";       key = "Q";        }
      { action = "Quit";             mods = "Command";       key = "W";        }
      { action = "Paste";            mods = "Shift";         key = "Insert";   }
      { action = "ResetFontSize";    mods = "Control";       key = "Key0";     }
      { action = "IncreaseFontSize"; mods = "Control";       key = "Equals";   }
      { action = "DecreaseFontSize"; mods = "Control";       key = "Subtract"; }
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

