{ pkgs, ... }:

{
  boot.plymouth = {
    enable = true;
    themePackages = with pkgs; [ avo.adi1090x-plymouth ];
    theme = "lone";
    # hexagon, green_loader, deus_ex, cuts, sphere, spinner_alt
  };
}
