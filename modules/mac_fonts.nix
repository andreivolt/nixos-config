{ pkgs, ... }:

{
  homebrew.casks = [
    "font-iosevka-term-nerd-font"
  ];

  fonts.packages = with pkgs; [
    atkinson-hyperlegible
  ];
}
