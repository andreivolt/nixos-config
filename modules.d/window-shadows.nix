{ lib, ... }:

with lib;

{
  services.compton = {
    enable = true;
    shadow = true; shadowOffsets = [ (-15) (-5) ]; shadowOpacity = "0.7";
    extraOptions = mkAfter "shadow-radius = 10;"; };
}
