{ config, lib, pkgs, ... }:

{
  imports = [
    ./cachix.nix
    ./modules/autoraise.nix
    ./modules/clojure.nix
    ./modules/command-not-found.nix
    ./modules/file-associations.nix
    ./modules/firewall.nix
    ./modules/flux.nix
    ./modules/gnupg.nix
    # ./modules/google-drive.nix
    ./modules/hammerspoon.nix
    ./modules/chatgpt.nix
    ./modules/htu.nix
    ./modules/iina.nix
    ./modules/jumpcut.nix
    ./modules/less.nix
    ./modules/mac_activity-monitor.nix
    ./modules/mac_dock.nix
    ./modules/mac_finder.nix
    ./modules/mac_fonts.nix
    ./modules/mac_keyboard.nix
    ./modules/mac_screenshots.nix
    ./modules/mac_terminal.nix
    ./modules/mac_tor.nix
    ./modules/mac_trackpad.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/ngrok.nix
    ./modules/nix.nix
    ./modules/playwright.nix
    ./modules/socks.nix
    ./modules/zsh/fzf.nix
  ]
  ++ [ <home-manager/nix-darwin> ];

  networking.hostName = "mac";

  environment.darwinConfig = "$HOME/drive/nixos-config/darwin-configuration.nix";

  users.users."${builtins.getEnv "USER"}" = {
    home = builtins.getEnv "HOME";
    description = "_";
  };

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  services.lorri.enable = true; # Nix direnv

  # require password immediately after sleep or screen saver begins
  system.defaults.CustomUserPreferences."com.apple.screensaver" = {
    askForPassword = 1;
    askForPasswordDelay = 0;
  };

  # don't create .DS_Store on network and removable media
  system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
    DSDontWriteNetworkStores = true;
    DSDontWriteUSBStores = true;
  };

  system.defaults.CustomUserPreferences."com:apple:AdLib" = {
    allowApplePersonalizedAdvertising = false;
    allowIdentifierForAdvertising = false;
  };

  # don't offer new disks for Time Machine backup
  system.defaults.CustomUserPreferences."com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;

  # disable window tiling gaps
  system.defaults.CustomUserPreferences."com.apple.WindowManager".EnableTiledWindowMargins = 0;

  # TODO
  system.defaults.CustomUserPreferences."com.apple.controlcenter"."NSStatusItem Visible Bluetooth" = 1;
  # TODO
  system.defaults.CustomUserPreferences."com.apple.controlcenter"."NSStatusItem Visible Display" = 0;

  # TODO
  system.defaults.CustomSystemPreferences.NSGlobalDomain.NSTextInsertionPointBlinkPeriodOn = 200;
  system.defaults.CustomSystemPreferences.NSGlobalDomain.NSTextInsertionPointBlinkPeriodOff = 200;

  # defaults write "com.apple.assistant.support" "Search Queries Data Sharing Status" '2'

  # system.defaults.CustomSystemPreferences.
  # defaults write "com.apple.Spotlight" "orderedItems" '({enabled=1;name=APPLICATIONS;},{enabled=1;name="MENU_EXPRESSION";},{enabled=0;name=CONTACT;},{enabled=1;name="MENU_CONVERSION";},{enabled=0;name="MENU_DEFINITION";},{enabled=0;name=SOURCE;},{enabled=0;name=DOCUMENTS;},{enabled=0;name="EVENT_TODO";},{enabled=0;name=DIRECTORIES;},{enabled=0;name=FONTS;},{enabled=0;name=IMAGES;},{enabled=0;name=MESSAGES;},{enabled=0;name=MOVIES;},{enabled=0;name=MUSIC;},{enabled=0;name="MENU_OTHER";},{enabled=0;name=PDF;},{enabled=0;name=PRESENTATIONS;},{enabled=0;name="MENU_SPOTLIGHT_SUGGESTIONS";},{enabled=0;name=SPREADSHEETS;},{enabled=1;name="SYSTEM_PREFS";},{enabled=0;name=TIPS;},{enabled=0;name=BOOKMARKS;},)'

  # turn off keyboard backlight after timeout
  system.defaults.CustomUserPreferences."com.apple.BezelServices".kDimTime = 5;

  # defaults write "app.monitorcontrol.MonitorControl" "useFineScaleBrightness" '1'

  # defaults write "io.tailscale.ipn.macos" "TailscaleStartOnLogin" '1'

  # disable sound when connecting charger
  system.defaults.CustomUserPreferences."com.apple.PowerChime".ChimeOnNoHardware = false;

  # disable toolbar rollover delay
  system.defaults.CustomUserPreferences.NSGlobalDomain.NSToolbarTitleViewRolloverDelay = 0;

  system.defaults.CustomUserPreferences."com.openai.chat"."desktopAppIconBehavior" = "{\"showOnlyInMenuBar\":{}}";

  # # Automatically quit printer app once the print jobs complete
  # system.defaults.CustomUserPreferences."com.apple.print.PrintingPrefs"."Quit When Finished" = true;

  system.defaults.NSGlobalDomain = {
    "com.apple.sound.beep.feedback" = 0; # feedback sound when system volume changes
    # "com.apple.sound.beep.volume" = 0.5;

    AppleFontSmoothing = 0;
    AppleInterfaceStyle = "Dark";
    AppleKeyboardUIMode = 3; # enable full keyboard access for controls
    AppleScrollerPagingBehavior = true; # jump to the spot that's clicked on the scroll bar
    AppleShowScrollBars = "WhenScrolling";
    NSNavPanelExpandedStateForSaveMode = true;
    # AppleActionOnDoubleClick = "Maximize"; # TODO
  };

  # system.defaults.universalaccess.reduceTransparency = true; # TODO

  home-manager.useGlobalPkgs = true; # Use the global pkgs that is configured via the system level nixpkgs options. This saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH, which is otherwise used for importing Nixpkgs.

  environment.systemPackages =
    with pkgs.macApps; [
    ] ++
    (import ./packages.nix pkgs);

  nixpkgs.config.allowUnfree = true;

  # enable Zsh completion for system packages
  environment.pathsToLink = [ "/share/zsh" ];

  nixpkgs.overlays =
    let
      nixpkgsUnstable = self: super: {
        nixpkgsUnstable = import <nixpkgs-unstable> { };
      };
    in
    [
      (import ./mac-apps)
      (import (builtins.fetchTarball { url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz; }))
      nixpkgsUnstable
    ];

  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
  programs.zsh.enableCompletion = false;

  system.stateVersion = 4;

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    caskArgs = {
      no_quarantine = true;
      require_sha = true;
    };

    brews = [
      "blueutil"
      "browser"
      "defaultbrowser"
      "detox"
      "ffmpeg"
      "imagesnap"
      "jakehilborn/jakehilborn/displayplacer"
      "launch"
      "mpv"
      "nethogs"
      "node"
      "pidof"
      "pipx"
      "python"
      "python-setuptools"
      "redshift"
      "swiftformat"
      "switchaudio-osx"
      "torsocks"
    ];

    casks = [
      "battery"
      "beeper"
      "command-x"
      "cursorcerer"
      "discord"
      "firefox@nightly"
      "forkgram-telegram"
      "fuse-t"
      "fuse-t-sshfs"
      "google-chrome"
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
      "prettyclean"
      "sublime-text"
      "tidal"
      "whatsapp"
      "zed"
      "zoom"
    ];

    masApps = {
      "Slack for Desktop" = 803453959;
      "Tailscale" = 1475387142;
      "TestFlight" = 899247664;
      "Xcode" = 497799835;
    };

    taps = [
      "borkdude/brew"
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/services"
      "jakehilborn/jakehilborn"
      "macos-fuse-t/homebrew-cask"
    ];
  };

  home-manager.users.andrei = { pkgs, ... }: rec {
    home.stateVersion = "23.11";

    programs.man.generateCaches = true;

    programs.zsh.enableCompletion = false;
    programs.zsh.enable = true;

    programs.zsh.initExtra = ''
      source ~/.zshrc.extra.zsh
    '';
  };

  system.defaults.smb.NetBIOSName = config.networking.hostName;
  system.defaults.smb.ServerDescription = config.networking.hostName;

  system.activationScripts.postUserActivation.text = ''
    echo "disable boot sound"
    sudo /usr/sbin/nvram SystemAudioVolume=%80

    echo "show the ~/Library folder"
    chflags nohidden ~/Library

    echo "reduce menu bar whitespace"
    defaults write -g NSStatusItemSelectionPadding -int 16
    defaults write -g NSStatusItemSpacing -int 16

    # xattr -d com.apple.quarantine /Applications/Forkgram.app

    # # TODO: apply settings immediately
    # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
