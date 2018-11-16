self: super: with super; {

terminal =
  let make-config = theme: {
    env.TERM = "xterm-16color";

    font = let font = "Roboto Mono"; in {
      size = 11.5;

      normal = { family = font; style = "Light"; };
      bold = { family = font; style = "Regular"; };
      italic = { family = font; style = "Light Italic"; };

      offset = { x = -1; y = -1; }; };

    colors = with theme; {
      primary = { inherit background foreground; };
      normal = { inherit black blue cyan green magenta red white yellow; };
      bright = { black = lightBlack; blue = lightBlue; cyan = lightCyan; green = lightGreen; magenta = lightMagenta; red = lightRed; white = lightWhite; yellow = lightYellow; };
      cursor = { cursor = highlight; text = white; }; };
    draw_bold_text_with_bright_colors = false;
    custom_cursor_colors = true;

    visual_bell.duration = 0;

    window.dimensions = { columns = 0; lines = 0; };

    window.padding = { x = 15; y = 10; };

    key_bindings = [
      { action = "Copy"; mods = "Control|Shift"; key = "C"; }
      { action = "Paste"; mods = "Shift"; key = "Insert"; }

      { action = "IncreaseFontSize"; mods = "Control"; key = "Equals"; }
      { action = "DecreaseFontSize"; mods = "Control"; key = "Subtract"; }
      { action = "ResetFontSize"; mods = "Control"; key = "Key0"; } ]; };
  in let _ = let
    config_light = writeText "config_light.yml" (lib.generators.toYAML {} (make-config (import /etc/nixos/theme.nix).light));
    config_dark = writeText "config_dark.yml" (lib.generators.toYAML {} (make-config (import /etc/nixos/theme.nix).dark));
  in ''
    #!/usr/bin/env bash

    [[ $1 == -l ]] && config=${config_light} && shift

    exec &>/dev/null setsid \
      ${alacritty}/bin/alacritty \
        --config-file ''${config:-${config_dark}} \
        "$@"'';
  in stdenv.mkDerivation rec {
    name = "terminal";
    unpackPhase = "true"; installPhase = "mkdir -p $out/bin && cp ${writeScript "_" _} $out/bin/${name}"; };

}
