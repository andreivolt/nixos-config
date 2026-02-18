{
  pkgs,
  lib,
  options,
  ...
}:
lib.mkMerge [
  {
    nixpkgs.config.input-fonts.acceptLicense = true;

    fonts.packages = with pkgs; [
      andrei.pragmasevka-nerd-font
      cascadia-code
      corefonts
      ubuntu-classic
      inter
      roboto
      dejavu_fonts
    ];
  }
  (lib.optionalAttrs (options.fonts ? fontconfig) {
    fonts.fontconfig.defaultFonts = {
      sansSerif = ["Inter"];
      monospace = ["Pragmasevka Nerd Font Light"];
    };
  })
]
