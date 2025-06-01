{...}: {
  homebrew.casks = ["google-drive"];

  system.defaults.CustomUserPreferences."com.google.drivefs.settings" = {
    AutomaticErrorReporting = 0;
    PromptToBackupDevices = false;
    SearchHotKey = 0;
  };

  system.activationScripts.googleDriveSymlinks.text = ''
    echo 'create Google Drive symlinks'
    sudo -u andrei ln -sfn "/Users/andrei/Google Drive/My Drive" /Users/andrei/drive
    sudo -u andrei ln -sfn /Users/andrei/drive/bin /Users/andrei/bin
  '';
}
