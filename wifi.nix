{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    iw
    wirelesstools
    wpa_supplicant
  ];
}
