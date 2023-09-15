{ pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
    input-fonts.acceptLicense = true;
  };

  fonts.packages = with pkgs; [ input-fonts ];
}
