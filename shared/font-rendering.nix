# Font rendering module - lucidglyph-style configuration
# Enables stem darkening and good hinting for better font visibility
{ pkgs, ... }:

{
  # FreeType stem darkening (like lucidglyph)
  environment.variables.FREETYPE_PROPERTIES = builtins.concatStringsSep " " [
    "autofitter:no-stem-darkening=0"
    "autofitter:darkening-parameters=500,0,1000,500,2500,500,4000,0"
    "cff:no-stem-darkening=0"
    "type1:no-stem-darkening=0"
    "t1cid:no-stem-darkening=0"
  ];

  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };
}
