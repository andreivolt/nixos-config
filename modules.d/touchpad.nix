{ pkgs, ... }:

{
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = true;
    accelSpeed = "0.6";
  };

  environment.systemPackages = with pkgs; [ libinput-gestures ];
}
