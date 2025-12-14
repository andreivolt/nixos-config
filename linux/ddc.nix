# DDC/CI support for external monitor brightness control
{pkgs, ...}: {
  hardware.i2c.enable = true;
  boot.kernelModules = ["i2c-dev"];
  users.users.andrei.extraGroups = ["i2c"];
  environment.systemPackages = [pkgs.ddcutil pkgs.ddcutil-service];
}
