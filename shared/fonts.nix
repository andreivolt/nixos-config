{pkgs, ...}: {
  # TODO
  # fonts.fontconfig.defaultFonts = {
  #   monospace = [ "Source Code Pro" ];
  #   sansSerif = [ "Source Sans Pro" ];
  # };

  nixpkgs.config.input-fonts.acceptLicense = true;

  fonts.packages = with pkgs; [
    andrei.pragmasevka-nerd-font
    cascadia-code
    corefonts
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    ubuntu-classic
    roboto
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

