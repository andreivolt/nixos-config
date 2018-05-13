{ config, pkgs, ... }:

{
  services.xserver.libinput = {
    enable = true;

    naturalScrolling = true;
    accelSpeed = "0.4";
  };

  environment.systemPackages = with pkgs; [ libinput-gestures ];
}
