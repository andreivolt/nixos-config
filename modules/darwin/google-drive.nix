{
  homebrew.casks = ["google-drive"];

  system.defaults.CustomUserPreferences."com.google.drivefs.settings" = {
    AutomaticErrorReporting = 0;
    PromptToBackupDevices = false;
    SearchHotKey = 0;
  };
}
