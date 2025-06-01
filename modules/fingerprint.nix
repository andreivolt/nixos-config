{pkgs, ...}: let
  # Path to the helper script
  lockWithFingerprintPath = pkgs.writeShellScript "lockWithFingerprint" ''
    #!/bin/sh

    # Use fingerprint for authentication if available
    if [[ $(fprintd-enroll -l) != "No devices available" ]]; then
      pam-auth-update --enable fprintd
      swaylock -f -c 000000 -- \
        pam:helper_path=${pkgs.fprintd}/lib/security/pam_fprintd.so
    else
      swaylock -f -c 000000
    fi
  '';
in {
  environment.systemPackages = [pkgs.fprintd];

  services.udev.packages = [pkgs.fprintd];

  services.dbus.packages = [pkgs.fprintd];

  services.fprintd.enable = true;

  services.fprintd.tod = {
    enable = true;
    driver = pkgs.libfprint-2-tod1-vfs0090;
  };
}
