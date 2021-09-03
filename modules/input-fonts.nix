{ pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
    input-fonts.acceptLicense = true;
  };

  fonts.fonts = with pkgs; [ input-fonts ];
}
