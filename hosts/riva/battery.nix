# Battery charge threshold and fullcharge command for Asahi
{ pkgs, ... }: {
  # Limit charging to 80% for battery longevity
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/macsmc-battery/charge_control_end_threshold - - - - 80"
  ];

  # Reset to 80% when charger connected (after fullcharge)
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="macsmc-battery", ATTR{status}=="Charging", RUN+="${pkgs.bash}/bin/sh -c 'echo 80 > /sys$devpath/charge_control_end_threshold'"
  '';

  # One-time full charge command
  environment.shellAliases.fullcharge = "echo 100 | sudo tee /sys/class/power_supply/macsmc-battery/charge_control_end_threshold";
}
