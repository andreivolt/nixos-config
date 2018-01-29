{ config, pkgs, ... }:

{
  services.redshift = {
    enable = true;
    latitude = "48.85";
    longitude = "2.35";
    temperature.night = 2500;
  };
}
