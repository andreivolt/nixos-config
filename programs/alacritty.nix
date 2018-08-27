{ config, lib, pkgs, ...}:

let
  theme = import ../theme.nix;
  monospaceFont = if builtins.getEnv("MONOSPACE_FONT_FAMILY") != "" then builtins.getEnv("MONOSPACE_FONT_FAMILY") else "Source Code Pro";

  colorSchemes = {
    light = {
      primary = {
        background = theme.background;
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

    dark = {
      bright = {
        black = "0x666666";
        blue = "0x7aa6da";
        cyan = "0x54ced6";
        green = "0x9ec400";
        magenta = "0xb77ee0";
        red = "0xff3334";
        white = "0xffffff";
        yellow = "0xe7c547";
      };
      cursor = {
        cursor = "0xffffff";
        text = "0x000000";
      };
      normal = {
        black = "0x000000";
        blue = "0x7aa6da";
        cyan = "0x70c0ba";
        green = "0xb9ca4a";
        magenta = "0xc397d8";
        red = "0xd54e53";
        white = "0xffffff";
        yellow = "0xe6c547";
      };
    };
  };

  mkConf = {
    colors,
    opacity ? 1,
    fontSize ?
      (if builtins.getEnv("TERMINAL_FONT_SIZE") != "" then lib.toInt builtins.getEnv("TERMINAL_FONT_SIZE") else 14)
  }: {
    background_opacity = opacity;
    colors = colors;
    custom_cursor_colors = true;
    dpi = { x = 180; y = 180; };
    draw_bold_text_with_bright_colors = false;
    font = {
      size = fontSize;
      normal = { family = monospaceFont; style = "Regular"; };
      bold = { family = monospaceFont; style = "Bold"; };
      italic = { family = monospaceFont; style = "Italic"; };
      offset = { x = 0; y = -3; };
      glyph_offset = { x = 0; y = 0; };
    };
    hide_cursor_when_typing = false;
    key_bindings = [
      { action = "Paste"; mods = "Control|Shift"; key = "V"; }
      { action = "Copy"; mods = "Control|Shift"; key = "C"; }
      { action = "Quit"; mods = "Command"; key = "Q"; }
      { action = "Quit"; mods = "Command"; key = "W"; }
      { action = "Paste"; mods = "Shift"; key = "Insert"; }
      { action = "ResetFontSize"; mods = "Control"; key = "Key0"; }
      { action = "IncreaseFontSize"; mods = "Control"; key = "Equals"; }
      { action = "DecreaseFontSize"; mods = "Control"; key = "Subtract"; }
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
      padding = { x = 20; y = 15; };
    };
  };

in {
  environment.systemPackages = with pkgs; [ alacritty ];

  home-manager.users.avo
    .xdg.configFile."alacritty/alacritty.yml".text =
      lib.generators.toYAML {}
        (mkConf { colors = colorSchemes.dark; });

  home-manager.users.avo
    .xdg.configFile."alacritty/config_scratchpad.yml".text =
      lib.generators.toYAML {}
        (mkConf {
          colors = colorSchemes.dark;
          opacity = 0.85;
          fontSize = 12;
        });
}

