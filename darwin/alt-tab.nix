{ config, pkgs, ... }:

{
  homebrew.casks = [ "alt-tab" ];

  system.defaults.CustomUserPreferences."com.lwouis.alt-tab-macos" = {
    appearanceStyle = 0;
    appearanceVisibility = 2;
    fadeOutAnimation = true;
    hideWindowlessApps = true;
    holdShortcut = "\\U2318";
    menubarIconShown = false;
    previewFadeInAnimation = false;
    previewFocusedWindow = true;
    showTitles = 2;
    titleTruncation = 1;
    windowDisplayDelay = 0;

    SUEnableAutomaticChecks = 0;
    updatePolicy = 0;
  };

  # defaults write "com.lwouis.alt-tab-macos" "blacklist" '"[{\"ignore\":\"0\",\"hide\":\"1\",\"bundleIdentifier\":\"com.McAfee.McAfeeSafariHost\"},{\"ignore\":\"0\",\"hide\":\"2\",\"bundleIdentifier\":\"com.apple.finder\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.microsoft.rdc.macos\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.teamviewer.TeamViewer\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"org.virtualbox.app.VirtualBoxVM\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.parallels.\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.citrix.XenAppViewer\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.citrix.receiver.icaviewer.mac\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.nicesoftware.dcvviewer\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.vmware.fusion\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.apple.ScreenSharing\"},{\"ignore\":\"2\",\"hide\":\"0\",\"bundleIdentifier\":\"com.utmapp.UTM\"},{\"ignore\":\"0\",\"hide\":\"1\",\"bundleIdentifier\":\"net.kovidgoyal.kitty\"},{\"ignore\":\"0\",\"hide\":\"1\",\"bundleIdentifier\":\"com.mitchellh.ghostty\"}]"'
}
