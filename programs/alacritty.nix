let
  theme = import ../challenger-deep-theme.nix;
  monospaceFont = "Source Code Pro";
  fontSize = 10;

in {
  config =
    import ../alacritty.nix {
      inherit theme monospaceFont;
      fontSize = fontSize;
    };
}

