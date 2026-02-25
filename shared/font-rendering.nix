# Font rendering — stem darkening + grayscale AA for Wayland HiDPI
{ ... }:

{
  # FreeType stem darkening (macOS-like weight for light fonts)
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
      enable = false;
      style = "none";
    };
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
  };
}
