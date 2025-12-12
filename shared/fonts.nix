{pkgs, ...}: {
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Roboto" ];
    monospace = [ "IosevkaTerm Nerd Font Mono" ];
  };

  nixpkgs.config.input-fonts.acceptLicense = true;

  fonts.packages = with pkgs; [
    # andrei.iosevka-sleek       # Custom geometric Iosevka (takes 30+ min to build)
    andrei.pragmasevka-nerd-font
    cascadia-code
    corefonts
    nerd-fonts.iosevka         # Fallback for Nerd Font symbols
    nerd-fonts.iosevka-term
    ubuntu-classic
    roboto
  ];
}

