{
  homebrew.casks = [ "topnotch" ];

  system.defaults.CustomUserPreferences."pl.maketheweb.TopNotch" = {
    isEnabled = 1;
    hideMenubarIcon = 1;
  };
}
