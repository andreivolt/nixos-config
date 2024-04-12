{
  homebrew.casks = [ "rectangle" ];

  system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
    hideMenubarIcon = true;
    launchOnLogin = true;
    doubleClickTitleBar = 3;
  };
}
