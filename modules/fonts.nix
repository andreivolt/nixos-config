{ pkgs, ... }:

{
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Source Code Pro" ];
    sansSerif = [ "Source Sans Pro" ];
  };
  fonts.fonts = with pkgs; [
    corefonts
    google-fonts
    nerdfonts
    jetbrains-mono
    d2coding
    proggyfonts
    ia-writer-duospace

    # emacs-all-the-icons-fonts
    # font-awesome-ttf
    # google-fonts
    # hack-font
    # hasklig
    # (iosevka.override {
    #   set = "custom";
    #   weights = ["light"];
    #   design = [
    #     "termlig"
    #     "v-asterisk-low"
    #     "v-at-short"
    #     "v-i-zshaped"
    #     "v-tilde-low"
    #     "v-underscore-low"
    #     "v-zero-dotted"
    #     "v-zshaped-l"
    #   ];
    # })
    # material-icons
    # nerdfonts
    # overpass
    # powerline-fonts
    # ubuntu_font_family
    # vistafonts
    # input-fonts
  ];
}
