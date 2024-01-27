{ pkgs, ... }:

with pkgs; {
  environment = {
    variables.PLAYWRIGHT_BROWSERS_PATH = playwright-driver.browsers.outPath;
    systemPackages = [ playwright ];
  };
}
