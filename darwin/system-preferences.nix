{config, ...}: {
  # disable Time Machine new disk prompts
  system.defaults.CustomUserPreferences."com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;

  # disable window tiling margins
  system.defaults.CustomUserPreferences."com.apple.WindowManager".EnableTiledWindowMargins = 0;

  # control center
  system.defaults.CustomUserPreferences."com.apple.controlcenter" = {
    "NSStatusItem Visible Bluetooth" = 1;
    "NSStatusItem Visible Display" = 0;
  };

  # menu bar clock
  system.defaults.CustomUserPreferences."com.apple.menuextra.clock" = {
    ShowDayOfWeek = 0;
  };

  # screen dimming delay in seconds
  system.defaults.CustomUserPreferences."com.apple.BezelServices".kDimTime = 5;

  # disable power chime sound
  system.defaults.CustomUserPreferences."com.apple.PowerChime".ChimeOnNoHardware = false;

  # auto-quit printer app after jobs complete
  system.defaults.CustomUserPreferences."com.apple.print.PrintingPrefs"."Quit When Finished" = true;

  # SMB settings
  system.defaults.smb = {
    NetBIOSName = config.networking.hostName;
    ServerDescription = config.networking.hostName;
  };
}