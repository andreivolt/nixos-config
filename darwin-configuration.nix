{
  config,
  pkgs,
  inputs,
  ...
}: {
  users.users.andrei = {
    home = "/Users/andrei";
    description = "_";
  };

  networking.hostName = "mac";

  system.stateVersion = 4;

  system.primaryUser = "andrei";

  imports = [
    ./modules/clojure.nix
    ./modules/fonts.nix
    ./modules/gnupg.nix
    ./modules/dnsmasq.nix
    ./modules/homebrew.nix
    ./modules/mac_autoraise.nix
    ./modules/mac_chatgpt.nix
    ./modules/mac_dock.nix
    ./modules/mac_file-associations.nix
    ./modules/mac_finder.nix
    ./modules/mac_google-drive.nix
    ./modules/mac_hammerspoon.nix
    ./modules/mac_htu.nix
    ./modules/mac_iina.nix
    ./modules/mac_jumpcut.nix
    ./modules/mac_socks-proxy.nix
    ./modules/mac_spotlight.nix
    ./modules/mac_tor.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/zsh-nix-completion.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # using Determinate Nix
  nix.enable = false;

  # services.lorri.enable = true;

  programs.zsh.enable = true; # needed for setting path
  programs.zsh.enableCompletion = false; # slow

  home-manager.useGlobalPkgs = true;
  home-manager.sharedModules = [
    inputs.mac-app-util.homeManagerModules.default
  ];

  home-manager.users.andrei = {pkgs, ...}: {
    home.stateVersion = "23.11";
    home.enableNixpkgsReleaseCheck = false;

    programs.man.generateCaches = true;

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true; # TODO
      enableCompletion = false;
      initContent = "source ~/.zshrc.extra.zsh;";
    };
  };

  environment.systemPackages = import ./packages.nix pkgs;

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults.NSGlobalDomain = {
    # Repeat character while key held instead of showing character accents menu
    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    "com.apple.sound.beep.feedback" = 0;
    # "com.apple.sound.beep.volume" = 0.5;
    AppleFontSmoothing = 0;
    AppleInterfaceStyle = "Dark";
    AppleKeyboardUIMode = 3;
    AppleScrollerPagingBehavior = true;
    AppleShowAllExtensions = true;
    NSNavPanelExpandedStateForSaveMode = true;
    # AppleActionOnDoubleClick = "Maximize"; # TODO
    "com.apple.trackpad.enableSecondaryClick" = true;
    NSWindowResizeTime = 0.001; # faster window resizing
  };

  system.defaults.ActivityMonitor = {
    IconType = 6; # CPU history in dock icon
    SortColumn = "CPUUsage";
    SortDirection = 0; # descending
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
    # swapLeftCommandAndLeftAlt = true; # TODO
  };

  system.defaults.screencapture = {
    location = "Clipboard";
    disable-shadow = true;
  };

  system.defaults.trackpad = {
    TrackpadRightClick = true;
    Clicking = true;
    TrackpadThreeFingerDrag = true;
  };

  system.defaults.CustomUserPreferences."com.apple.menuextra.clock" = {
    ShowDayOfWeek = 0;
  };

  system.defaults.CustomSystemPreferences.NSGlobalDomain = {
    "com.apple.trackpad".scaling = 1.5;
    NSTextInsertionPointBlinkPeriodOn = 200;
    NSTextInsertionPointBlinkPeriodOff = 200;
    NSToolbarTitleViewRolloverDelay = 0;
  };

  # screen lock settings
  system.defaults.CustomUserPreferences."com.apple.screensaver" = {
    askForPassword = 1;
    askForPasswordDelay = 0;
  };

  # prevent creation of .DS_Store files
  system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
    DSDontWriteNetworkStores = true;
    DSDontWriteUSBStores = true;
  };

  # ads
  system.defaults.CustomUserPreferences."com.apple.AdLib" = {
    allowApplePersonalizedAdvertising = false;
    allowIdentifierForAdvertising = false;
  };

  # disable Time Machine new disk prompts
  system.defaults.CustomUserPreferences."com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;

  # disable window tiling margins
  system.defaults.CustomUserPreferences."com.apple.WindowManager".EnableTiledWindowMargins = 0;

  # system.defaults.controlcenter = {
  #   Bluetooth = true;
  #   Display = false;
  # };
  system.defaults.CustomUserPreferences."com.apple.controlcenter" = {
    "NSStatusItem Visible Bluetooth" = 1;
    "NSStatusItem Visible Display" = 0;
  };

  # screen dimming delay in seconds
  system.defaults.CustomUserPreferences."com.apple.BezelServices".kDimTime = 5;

  # disable power chime sound
  system.defaults.CustomUserPreferences."com.apple.PowerChime".ChimeOnNoHardware = false;

  # auto-quit printer app after jobs complete
  system.defaults.CustomUserPreferences."com.apple.print.PrintingPrefs"."Quit When Finished" = true;

  # disable Siri data sharing
  system.defaults.CustomUserPreferences."com.apple.assistant.support"."Search Queries Data Sharing Status" = 2;

  # system.defaults.CustomUserPreferences."com.apple.Safari".ShowFullURLInSmartSearchField = true; # TODO

  system.defaults.CustomUserPreferences."com.apple.AppleMultitouchTrackpad".DragLock = true;

  # defaults write "com.apple.bird" "optimize-storage" '0' # TODO iCloud disable auto sync

  # system.defaults.universalaccess.reduceTransparency = true; # TODO

  system.defaults.smb = {
    NetBIOSName = config.networking.hostName;
    ServerDescription = config.networking.hostName;
  };

  # firewall
  system.defaults.alf = {
    globalstate = 2;
    stealthenabled = 1;
  };

  # disable smart quotes
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;

  # system.activationScripts.postUserActivation.text = ''
  #   echo 'disable boot sound'
  #   sudo /usr/sbin/nvram SystemAudioVolume=%80
  #
  #   echo 'reduce menu bar whitespace'
  #   defaults write -g NSStatusItemSelectionPadding -int 16
  #   defaults write -g NSStatusItemSpacing -int 16
  #
  #   echo 'keep awake when remote session active when on power'
  #   sudo pmset -c ttyskeepawake 1
  #   sudo pmset -b ttyskeepawake 0
  #
  #   echo 'disable auto brightness'
  #   sudo defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Display Enabled" -bool false
  #
  #   ln -sfn ~/Google\ Drive/My\ Drive ~/drive
  #   ln -sfn ~/drive/bin ~/bin
  #
  #   /opt/homebrew/bin/defaultbrowser chrome
  #
  #   osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"'
  #
  #   # # TODO: apply settings immediately
  #   # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  # '';

}
