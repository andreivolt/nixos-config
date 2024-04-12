{ config, pkgs, ... }:

{
  users.users."${builtins.getEnv "USER"}" = {
    home = builtins.getEnv "HOME";
    description = "_";
  };

  networking.hostName = "mac";

  system.stateVersion = 4;

  environment.darwinConfig = "$HOME/drive/nixos-config/darwin-configuration.nix";

  imports = [
    ./modules/clojure.nix
    ./modules/fonts.nix
    ./modules/gnupg.nix
    ./modules/local-test-domain.nix
    ./modules/mac_autoraise.nix
    ./modules/mac_chatgpt.nix
    ./modules/mac_file-associations.nix
    ./modules/mac_google-drive.nix
    ./modules/mac_hammerspoon.nix
    ./modules/mac_htu.nix
    ./modules/mac_iina.nix
    ./modules/mac_jumpcut.nix
    ./modules/mac_socks-proxy.nix
    ./modules/mac_tor.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/nix.nix
    ./modules/zsh-nix-completion.nix
    ./overlays/mozilla.nix
    ./overlays/unstable.nix
  ] ++ [ <home-manager/nix-darwin> ];

  nixpkgs.config.allowUnfree = true;

  services.lorri.enable = true;

  services.nix-daemon.enable = true;

  programs.zsh.enable = true; # needed for setting path
  programs.zsh.enableCompletion = false; # slow

  home-manager.useGlobalPkgs = true;

  home-manager.users.andrei = { pkgs, ... }: {
    home.stateVersion = "23.11";

    programs.man.generateCaches = true;

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true; # TODO
      enableCompletion = false;
      initExtra = "source ~/.zshrc.extra.zsh;";
    };
  };

  environment.systemPackages = import ./packages.nix pkgs;

  security.pam.enableSudoTouchIdAuth = true;

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
    AppleShowScrollBars = "WhenScrolling";
    NSNavPanelExpandedStateForSaveMode = true;
    # AppleActionOnDoubleClick = "Maximize"; # TODO
    "com.apple.trackpad.enableSecondaryClick" = true;
    NSTableViewDefaultSizeMode = 3; # large finder sidebar icons
    NSWindowResizeTime = 0.001; # faster window resizing
  };

  system.defaults.ActivityMonitor = {
    IconType = 6; # CPU history in dock icon
    SortColumn = "CPUUsage";
    SortDirection = 0; # descending
  };

  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.1;
    autohide-time-modifier = 0.1;
    enable-spring-load-actions-on-all-items = false;
    expose-animation-duration = 0.1;
    mineffect = "scale";
    minimize-to-application = true;
    orientation = "bottom";
    # scroll-to-open = true; # TODO
    show-recents = false;
    showhidden = true;
    tilesize = 48;
    wvous-br-corner = 5; # bottom-right corner starts screensaver
    wvous-tr-corner = 2; # top-right corner show windows
  };

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

  system.defaults.CustomUserPreferences."com.apple.Safari".ShowFullURLInSmartSearchField = true;

  system.defaults.CustomUserPreferences."com.apple.AppleMultitouchTrackpad".DragLock = true;

  system.defaults.CustomUserPreferences."com.apple.Spotlight"."orderedItems" = [
    { enabled = 1; name = "APPLICATIONS"; }
    { enabled = 1; name = "MENU_EXPRESSION"; }
    { enabled = 0; name = "CONTACT"; }
    { enabled = 1; name = "MENU_CONVERSION"; }
    { enabled = 0; name = "MENU_DEFINITION"; }
    { enabled = 0; name = "SOURCE"; }
    { enabled = 1; name = "DOCUMENTS"; }
    { enabled = 0; name = "EVENT_TODO"; }
    { enabled = 0; name = "DIRECTORIES"; }
    { enabled = 0; name = "FONTS"; }
    { enabled = 0; name = "IMAGES"; }
    { enabled = 0; name = "MESSAGES"; }
    { enabled = 0; name = "MOVIES"; }
    { enabled = 0; name = "MUSIC"; }
    { enabled = 0; name = "MENU_OTHER"; }
    { enabled = 0; name = "PDF"; }
    { enabled = 0; name = "PRESENTATIONS"; }
    { enabled = 0; name = "MENU_SPOTLIGHT_SUGGESTIONS"; }
    { enabled = 0; name = "SPREADSHEETS"; }
    { enabled = 1; name = "SYSTEM_PREFS"; }
    { enabled = 0; name = "TIPS"; }
    { enabled = 0; name = "BOOKMARKS"; }
  ];

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

  system.activationScripts.postUserActivation.text = ''
    echo 'disable boot sound'
    sudo /usr/sbin/nvram SystemAudioVolume=%80

    echo 'reduce menu bar whitespace'
    defaults write -g NSStatusItemSelectionPadding -int 16
    defaults write -g NSStatusItemSpacing -int 16

    echo 'disable auto brightness'
    sudo defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Display Enabled" -bool false

    # ln -fs ~/Google\ Drive/My\ Drive drive
    # ln -fs ~/drive/bin ~/bin

    /opt/homebrew/bin/defaultbrowser nightly

    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"'

    # # TODO: apply settings immediately
    # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    caskArgs = {
      no_quarantine = true;
      # require_sha = true;
    };

    brews = [
      "blueutil"
      "browser"
      "defaultbrowser"
      "detox"
      "ffmpeg"
      "imagesnap"
      "jakehilborn/jakehilborn/displayplacer"
      "mpv"
      "nethogs"
      "pidof"
      "pipx"
      "redshift"
      "switchaudio-osx"
    ];

    casks = [
      "battery"
      "beeper"
      "command-x"
      "cursorcerer"
      "firefox@nightly"
      "hammerspoon"
      "iina"
      "jumpcut"
      "keycastr"
      "kitty"
      "mimestream"
      "monitorcontrol"
      "nomachine"
      "obs"
      "orbstack"
      "sublime-text"
      "tidal"
      "whatsapp"
    ];

    masApps = {
      "Slack for Desktop" = 803453959;
      "Tailscale" = 1475387142;
      "TestFlight" = 899247664;
      "Xcode" = 497799835;
    };

    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/services"
      "jakehilborn/jakehilborn"
    ];
  };
}
