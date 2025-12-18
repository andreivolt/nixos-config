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
      roboto
    ];
  }
  (lib.optionalAttrs (options.fonts ? fontconfig) {
    fonts.fontconfig.defaultFonts = {
      sansSerif = ["Roboto"];
      monospace = ["Pragmasevka Nerd Font Light"];
    };
  })
]
