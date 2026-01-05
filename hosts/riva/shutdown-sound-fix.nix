# Fix for sound devices triggering sound.target during shutdown on Asahi Linux
# Causes delays and "Transaction contradicts existing jobs" warnings
# See: https://github.com/systemd/systemd/issues/38987
{pkgs, ...}: {
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "15s";
    ShutdownWatchdogSec = "30s";
  };

  systemd.targets."sound".unitConfig = {
    Conflicts = "shutdown.target reboot.target";
    Before = "shutdown.target reboot.target";
  };

  # Only trigger sound.target on device add, not change/remove during shutdown
  services.udev.extraRules = ''
    ACTION!="add", SUBSYSTEM=="sound", ENV{SYSTEMD_WANTS}=""
  '';
}
