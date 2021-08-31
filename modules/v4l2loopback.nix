{ pkgs, config, ... }:

{
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback.out ];
  boot.extraModprobeConfig = "options v4l2loopback exclusive_caps=1"; # Chrome needs exclusive_caps=1
  environment.systemPackages = with pkgs; [ linuxPackages.v4l2loopback ];
}
