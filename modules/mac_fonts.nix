{ pkgs, ... }:

{
  homebrew.casks = [
    "font-fira-code-nerd-font"
    "font-fira-mono-nerd-font"
    "font-hasklug-nerd-font"
    "font-iosevka"
    "font-iosevka-nerd-font"
    "font-jetbrains-mono-nerd-font"
    "font-monofur-nerd-font"
    "font-roboto-mono-nerd-font"
    "font-victor-mono-nerd-font"
    # TODO font-iosevka{-aile,-curly,-etoile}
  ];

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    atkinson-hyperlegible
    nerdfonts
    ubuntu_font_family
  ];
}
