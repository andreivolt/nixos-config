{ config, pkgs, ... }:

{
  system.defaults.CustomUserPreferences."com.lwouis.alt-tab-macos" = {
    defaults write "app.monitorcontrol.MonitorControl" "hideVolume" '1'
    defaults write "app.monitorcontrol.MonitorControl" "SUEnableAutomaticChecks" '0'
  };
}
