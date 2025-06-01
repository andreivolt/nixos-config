{...}: {
  security.pam.services.sudo_local.touchIdAuth = true;

  # screen lock settings
  system.defaults.CustomUserPreferences."com.apple.screensaver" = {
    askForPassword = 1;
    askForPasswordDelay = 0;
  };

  # firewall
  system.defaults.alf = {
    globalstate = 2;
    stealthenabled = 1;
  };
}