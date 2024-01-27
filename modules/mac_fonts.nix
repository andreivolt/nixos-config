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
    "font-source-code-pro-for-powerline"
    "font-victor-mono-nerd-font"
  ];

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    # corefonts # TODO error
    # emacs-all-the-icons-fonts
    # font-awesome-ttf
    # google-fonts
    # hasklig
    # jetbrains-mono
    # material-icons
    # noto-fonts-emoji
    # overpass
    # powerline-fonts
    # twitter-color-emoji
    # whatsapp-emoji-font
    atkinson-hyperlegible
    cascadia-code
    d2coding
    hack-font
    ia-writer-duospace
    nerdfonts
    proggyfonts
    sudo-font
    ubuntu_font_family
    vistafonts
  ];
}
