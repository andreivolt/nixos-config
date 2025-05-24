{
  config,
  pkgs,
  ...
}: {
  system.defaults.finder = {
    _FXShowPosixPathInTitle = true;
    AppleShowAllExtensions = true;
    FXDefaultSearchScope = "SCcf"; # scope search to current folder
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "Nlsv"; # list view
    ShowPathbar = true;
    ShowStatusBar = true;
  };

  system.defaults.CustomUserPreferences."com.apple.finder" = {
    WarnOnEmptyTrash = false;
    NewWindowTarget = "PfHm"; # new windows open in home dir
    _FXSortFoldersFirst = true; # TODO
  };
}
