{ config, lib, pkgs, ...}:

let
  theme = import ../theme.nix;

  monospaceFont =
    if builtins.getEnv("MONOSPACE_FONT_FAMILY") != ""
    then builtins.getEnv("MONOSPACE_FONT_FAMILY")
    else "Roboto Mono";

  colorSchemes = {
    light = {
      primary = { background = theme.background; foreground = theme.foreground;
      };
      cursor = { cursor = theme.highlight; text = theme.white;
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
        black = theme.lightBlack;
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
      cursor = { cursor = theme.blue; text = "0xcccccc";
      };
      bright = {
        black = "0x333333";
        blue = "0x217dd9";
        cyan = "0x54ced6";
        green = "0x45e67a";
        magenta = "0xb77ee0";
        red = "0xff3334";
        white = "0x888888";
        yellow = "0xe7c547";
      };
      normal = {
        black = "0x111111";
        blue = "0x217dd9";
        cyan = "0x198078";
        green = "0x45e67a";
        magenta = "0xc397d8";
        red = "0xd54e53";
        white = "0xdddddd";
        yellow = "0xe6c547";
      };
    };
  };

  mkConf = {
    colors,
    opacity ? 1
  }: {
    background_opacity = opacity;
    colors = colors;

    custom_cursor_colors = true;
    hide_cursor_when_typing = false;

    dpi = { x = 180; y = 180; };
    draw_bold_text_with_bright_colors = false;
    font = {
      size = (if builtins.getEnv("TERMINAL_FONT_SIZE") != "" then lib.toInt builtins.getEnv("TERMINAL_FONT_SIZE") else 13);

      normal = { family = monospaceFont; style = "Light"; };
      bold = { family = monospaceFont; style = "Bold"; };
      italic = { family = monospaceFont; style = "Italic"; };

      offset = { x = 0; y = -1; };
      glyph_offset = { x = -1; y = 0; };
    };
    key_bindings = [
      { action = "Copy"; mods = "Control|Shift"; key = "C"; }
      { action = "Paste"; mods = "Shift"; key = "Insert"; }

      { action = "IncreaseFontSize"; mods = "Control"; key = "Equals"; }
      { action = "DecreaseFontSize"; mods = "Control"; key = "Subtract"; }
      { action = "ResetFontSize"; mods = "Control"; key = "Key0"; }
    ];
    selection.semantic_escape_chars = ";│`|:\"' ()[]{}<>";
    tabspaces = 4;
    visual_bell.duration = 0;
    window = {
      dimensions = { columns = 0; lines = 0; };
      padding = { x = 30; y = 20; };
    };
  };

  kitty-config = pkgs.writeText "kitty-config" (with import ../theme.nix; ''
    font_family      SF Mono Light
    italic_font      SF Mono Light Italic
    bold_font        SF Mono Regular
    bold_italic_font SF Mono Regular Italic

    font_size 11

    font_size_delta 0.5

    window_padding_width 10

    adjust_line_height 0
    adjust_column_width -1

    box_drawing_scale 0.001, 1, 1.5, 2

    url_color ${blue}
    url_style single

    input_delay 0

    cursor ${highlight}

    color0 ${background}
    color8 ${gray}

    color7 ${foreground}
    color15 ${lightWhite}

    color1 ${red}
    color9 ${lightRed}

    color2 ${green}
    color10 ${lightGreen}

    color3 ${yellow}
    color11 ${lightYellow}

    color4 ${blue}
    color12 ${lightBlue}

    color5 ${magenta}
    color13 ${lightMagenta}

    color6 ${cyan}
    color14 ${lightCyan}
  '');

in {
  environment.systemPackages = with pkgs; let
    terminal = with pkgs; stdenv.mkDerivation rec {
      name = "terminal";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        exec &>/dev/null

        ${pkgs.kitty}/bin/kitty --config ${kitty-config} &

        disown

      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    terminal-scratchpad = with pkgs; stdenv.mkDerivation rec {
      name = "terminal-scratchpad";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        exec &>/dev/null

        ${pkgs.kitty}/bin/kitty \
          --config ${kitty-config} \
          --class scratchpad --title scratchpad &

        disown
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    #terminal = with pkgs; stdenv.mkDerivation rec {
    #  name = "terminal";

    #  src = [(let
    #    conf = pkgs.writeText "config.yml" (lib.generators.toYAML {} (mkConf { colors = colorSchemes.dark; }));
    #  in pkgs.writeScript name ''
    #    #!/usr/bin/env bash

    #    exec &>/dev/null

    #    ${pkgs.alacritty}/bin/alacritty --config-file ${conf} &

    #    disown
    #  '')];

    #  unpackPhase = "true";

    #  installPhase = ''
    #    mkdir -p $out/bin
    #    cp $src $out/bin/${name}
    #  '';
    #};

    #terminal-scratchpad = with pkgs; stdenv.mkDerivation rec {
    #  name = "terminal-scratchpad";

    #  src = [(let
    #    conf = pkgs.writeText "config.yml" (lib.generators.toYAML {} (mkConf { colors = colorSchemes.dark; opacity = 0.9; }));
    #  in pkgs.writeScript name ''
    #    #!/usr/bin/env bash

    #    exec &>/dev/null

    #    ${pkgs.alacritty}/bin/alacritty \
    #      --config-file ${conf} \
    #      --class scratchpad --title scratchpad &

    #    disown
    #  '')];

    #  unpackPhase = "true";

    #  installPhase = ''
    #    mkdir -p $out/bin
    #    cp $src $out/bin/${name}
    #  '';
    #};
  in [
    terminal
    terminal-scratchpad
  ];
}
