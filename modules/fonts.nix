{pkgs, ...}: {
  # TODO
  # fonts.fontconfig.defaultFonts = {
  #   monospace = [ "Source Code Pro" ];
  #   sansSerif = [ "Source Sans Pro" ];
  # };

  fonts.packages = with pkgs; [
    atkinson-hyperlegible
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    nerd-fonts.commit-mono
    ubuntu_font_family
  ];
}
# (iosevka.override {
#   set = "custom";
#   privateBuildPlan = {
#     family = "Iosevka Custom";
#     spacing = "normal";
#     serifs = "sans";
#     variants = {
#       design.capital-j = "serifless";
#       italic.i = "tailed";
#     };
#   };
#   # design = [
#   #   "termlig"
#   #   "v-asterisk-low"
#   #   "v-at-short"
#   #   "v-i-zshaped"
#   #   "v-tilde-low"
#   #   "v-underscore-low"
#   #   "v-zero-dotted"
#   #   "v-zshaped-l"
#   # ];
# })

