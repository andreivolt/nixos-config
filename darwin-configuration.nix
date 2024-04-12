{ config, lib, pkgs, ... }:

{
  imports = [
    # ./modules/ipfs.nix
    ./cachix.nix
    ./modules/autoraise.nix
    ./modules/clojure
    ./modules/command-not-found.nix
    ./modules/file-associations.nix
    ./modules/firewall.nix
    ./modules/flux.nix
    ./modules/gnupg.nix
    ./modules/google-drive.nix
    ./modules/hammerspoon.nix
    ./modules/htu.nix
    ./modules/iina.nix
    ./modules/jumpcut.nix
    ./modules/less.nix
    ./modules/mac_activity-monitor.nix
    ./modules/mac_dock.nix
    ./modules/mac_finder.nix
    ./modules/mac_fonts.nix
    ./modules/mac_keyboard.nix
    ./modules/mac_map-caps-to-esc.nix
    ./modules/mac_nginx.nix
    ./modules/mac_screenshots.nix
    ./modules/mac_terminal.nix
    ./modules/mac_tor.nix
    ./modules/mac_trackpad.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/ngrok.nix
    ./modules/nix.nix
    ./modules/playwright.nix
    ./modules/zsh/fzf.nix
  ]
  ++ [ <home-manager/nix-darwin> ];

  networking.hostName = "mac";

  environment.darwinConfig = "$HOME/drive/nixos-config/darwin-configuration.nix";

  users.users."${builtins.getEnv "USER"}" = {
    name = builtins.getEnv "USER";
    home = builtins.getEnv "HOME";
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

  # TODO
  system.defaults.CustomSystemPreferences.NSGlobalDomain.NSTextInsertionPointBlinkPeriodOn = 200;
  system.defaults.CustomSystemPreferences.NSGlobalDomain.NSTextInsertionPointBlinkPeriodOff = 200;

  # turn off keyboard backlight after timeout
  system.defaults.CustomUserPreferences."com.apple.BezelServices".kDimTime = 5;

  # disable sound when connecting charger
  system.defaults.CustomUserPreferences."com.apple.PowerChime".ChimeOnNoHardware = false;

  # TextEdit default to plain text
  system.defaults.CustomUserPreferences."com.apple.TextEdit".RichText = 0;

  # # Automatically quit printer app once the print jobs complete
  # system.defaults.CustomUserPreferences."com.apple.print.PrintingPrefs"."Quit When Finished" = true;

  system.defaults.NSGlobalDomain = {
    "com.apple.sound.beep.feedback" = 0; # feedback sound when system volume changes
    # "com.apple.sound.beep.volume" = 0.5;

    AppleFontSmoothing = 0;
    AppleInterfaceStyle = "Dark";
    AppleKeyboardUIMode = 3; # enable full keyboard access for controls
    AppleScrollerPagingBehavior = true; # jump to the spot that's clicked on the scroll bar
    AppleShowAllExtensions = true;
    AppleShowScrollBars = "Always";
    NSNavPanelExpandedStateForSaveMode = true;
    # AppleActionOnDoubleClick = "Maximize"; # TODO
  };

  # system.defaults.universalaccess.reduceTransparency = true; # TODO

  home-manager.useGlobalPkgs = true; # Use the global pkgs that is configured via the system level nixpkgs options. This saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH, which is otherwise used for importing Nixpkgs.

  environment.systemPackages =
    with pkgs.macApps; [
      chat-tab
      pref-edit
      superwhisper
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
      # (import (builtins.fetchTarball { url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz; }))
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
      "amazon-ecs-cli"
      "blueutil"
      "borkdude/brew/jet"
      "browser"
      "detox"
      "ffmpeg"
      "imagesnap"
      "jakehilborn/jakehilborn/displayplacer"
      "jqp"
      "launch"
      "libiconv"
      "nethogs"
      "node"
      "nvm"
      "pidof"
      "pipx"
      "pkgxdev/made/pkgx"
      "pushtotalk"
      "python"
      "python-setuptools"
      "qsv"
      "schappim/ocr/ocr"
      "sleuthkit"
      "swiftformat"
      "switchaudio-osx"
      "torsocks"
      # "askgitdev/treequery/treequery" # TODO
      # "csvtk"
      # "espanso" # TODO
      # "ext4fuse" # TODO
      # "felixkratz/formulae/svim"
      # "fig" # TODO
      # "hgrep" # TODO
      # "withgraphite/tap/graphite"
    ];

    casks = [
      "android-commandlinetools"
      "battery"
      "beeper"
      "caffeine"
      "choosy"
      "cursorcerer"
      "discord"
      "firefox"
      "flux"
      "forkgram-telegram"
      "google-chrome"
      "google-drive"
      "hammerspoon"
      "iina"
      "jumpcut"
      "keycastr"
      "kitty"
      "mimestream"
      "orbstack"
      "prettyclean"
      "rectangle"
      "rocket"
      "roon"
      "spotify"
      "steam"
      "sublime-text"
      "tidal"
      "tor-browser"
      "whatsapp"
      "zoom"
      # "alfred"
      # "alt-tab"
      # "android-file-transfer"
      # "audacity"
      # "bettertouchtool"
      # "blackhole-2ch" # TODO
      # "blender"
      # "brave-browser"
      # "cheatsheet"
      # "cleanmymac"
      # "cloudapp"
      # "contexts"
      # "cord"
      # "coscreen"
      # "daisydisk"
      # "dash"
      # "deepl"
      # "dropbox"
      # "ears"
      # "electrum"
      # "figma"
      # "foobar2000"
      # "fork"
      # "genymotion"
      # "github"
      # "gitify"
      # "gitkraken" "gitkraken-cli"
      # "hiddenbar"
      # "hot"
      # "inkscape"
      # "ioquake3"
      # "karabiner-elements"
      # "keepingyouawake"
      # "kindavim"
      # "knockknock"
      # "lapce"
      # "launchbar"
      # "libreoffice"
      # "little-snitch"
      # "macfuse"
      # "mailmate"
      # "miniconda"
      # "mupdf"
      # "mutify"
      # "muzzle"
      # "odrive"
      # "parsec"
      # "polypane"
      # "proxyman"
      # "raycast"
      # "shortcat"
      # "signal"
      # "sizzy"
      # "sloth"
      # "soundsource"
      # "stats"
      # "swift-quit"
      # "tableplus"
      # "tailscale"
      # "textual"
      # "tuple"
      # "ukelele"
      # "unified-remote"
      # "utm"
      # "vlc"
      # "vysor"
      # "warp"
      # "webtorrent"
      # "wireshark"
    ];

    # TODO macos-pasteboard
    # TODO piknik
    # TODO statsd
    # TODO taiko
    masApps = {
      "1Blocker" = 1365531024;
      "AdGuard for Safari" = 1440147259;
      "Archive Page Extension" = 6446372766;
      "Command X" = 6448461551;
      "Hush" = 1544743900;
      "Hyperduck" = 6444667067;
      "Jiffy" = 1502527999;
      "Nitefall" = 1575190591;
      "Shareful" = 1522267256;
      "Slack for Desktop" = 803453959;
      "Super Agent" = 1568262835;
      "Tailscale" = 1475387142;
      "TestFlight" = 899247664;
      "Vimari" = 1480933944;
      "Xcode" = 497799835;
      "darker" = 1637413102;
      # "Actions" = 1586435171;
      # "Battery Indicator" = 1206020918;
      # "Black Out" = 1319884285;
      # "Camera Preview" = 1632827132;
      # "Command X" = 6448461551;
      # "Day Progress" = 6450280202;
      # "Element X - Secure messenger" = 1631335820;
      # "Lungo" = 1263070803;
      # "MetaMask - Blockchain Wallet" = 1438144202;
      # "Noir – Dark Mode for Safari" = 1592917505;
      # "One Task" = 6465745322;
      # "Penguin - Plist Editor" = 1634084815;
      # "Recordia" = 1529006487;
      # "SingleFile for Safari" = 6444322545;
      # "Speediness" = 1596706466;
      # "System Color Picker" = 1545870783;
      # "Velja" = 1607635845;
    };

    taps = [
      "schappim/ocr"
      "borkdude/brew"
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/services"
      "jakehilborn/jakehilborn"
      "noahgorstein/tap" # jqp
      "pkgxdev/made"
      "yulrizka/tap" # pushtotalk
      # "federico-terzi/espanso"
      # "felixkratz/formulae" # svim
      # "withgraphite/tap"
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

  # system.defaults.universalaccess.reduceTransparency = true;

  system.activationScripts.postUserActivation.text = ''
    # # TODO: apply settings immediately
    # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

    echo "disable boot sound"
    sudo /usr/sbin/nvram SystemAudioVolume=%80

    echo "show the ~/Library folder"
    chflags nohidden ~/Library

    echo "reduce menu bar whitespace"
    defaults write -g NSStatusItemSelectionPadding -int 20
    defaults write -g NSStatusItemSpacing -int 20
  '';
}
