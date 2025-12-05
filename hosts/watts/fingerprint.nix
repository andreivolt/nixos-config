{pkgs, ...}: {
  environment.systemPackages = [pkgs.fprintd];

  services.udev.packages = [pkgs.fprintd];

  services.dbus.packages = [pkgs.fprintd];

  services.fprintd.enable = true;
}
