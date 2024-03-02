{ config, lib, pkgs, ... }:

{
  imports = [
    # ./modules/firewall.nix
    # ./modules/git.nix
    # ./modules/ipfs.nix
    # ./modules/mac_postgres.nix
    ./cachix.nix
    ./modules/bat.nix
    ./modules/clojure
    ./modules/clojure/boot
    ./modules/clojure/rebel-readline.nix
    ./modules/command-not-found.nix
    ./modules/curl.nix
    ./modules/direnv.nix
    ./modules/file-associations.nix
    ./modules/flux.nix
    ./modules/gnupg.nix
    ./modules/google-drive.nix
    ./modules/hammerspoon.nix
    ./modules/htu_autobackup.nix
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
    ./modules/python-portaudio.nix
    ./modules/readline/inputrc.nix
    ./modules/ruby.nix
    ./modules/zsh/fzf.nix
  ]
  ++ [<home-manager/nix-darwin>];

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
  };

  # system.defaults.universalaccess.reduceTransparency = true; # TODO

  home-manager.useGlobalPkgs = true; # Use the global pkgs that is configured via the system level nixpkgs options. This saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH, which is otherwise used for importing Nixpkgs.

  environment.systemPackages =
    with pkgs.macApps; [
      chat-tab
      pref-edit
      pretty-clean
      superwhisper
      telegram
    ] ++
    (import ./packages.nix pkgs);

  nixpkgs.config.allowUnfree = true;

  # enable Zsh completion for system packages
  environment.pathsToLink = [ "/share/zsh" ];

  nixpkgs.overlays = let
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable = import <nixpkgs-unstable> {};
    };
  in [
    (import ./mac-apps)
    (import (builtins.fetchTarball { url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz; }))
    nixpkgsUnstable
  ];

  # services.emacs.package = pkgs.emacs-unstable;
  # services.emacs.enable = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
  programs.zsh.enableCompletion = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
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

    casks = [
      "android-commandlinetools"
      "appcleaner"
      "battery" # battery charge limiter
      "beeper" # multi-service messenger
      "blackhole-2ch" # virtual audio device
      "caffeine" # inhibit sleep
      "choosy" # rules for opening url with different browsers
      "cursorcerer" # autohide cursor
      "discord"
      "firefox"
      "flux"
      "google-chrome"
      "google-drive"
      "grandperspective" # disk usage visualizer
      "hammerspoon" # desktop automation
      "iina" # video player
      "jumpcut" # clipboard manager
      "keycastr" # show keys
      "kitty" # terminal
      "macfuse" # FUSE filesystems
      "mimestream" # email client
      "neovide" # Neovim GUI
      "orbstack" # Docker
      "proxyman" # inspect network traffic
      "rectangle" # window snap tile
      "rocket" # emoji picker
      "roon"
      "spotify"
      "steam"
      "sublime-text"
      "telegram" # messaging
      "tidal" # music
      "tor-browser"
      "visual-studio-code"
      "whatsapp"
      # "alfred" # launcher
      # "alt-tab" # window management
      # "android-file-transfer"
      # "audacity" # audio editor
      # "bettertouchtool"
      # "blender"
      # "brave-browser"
      # "cheatsheet" # show keybindings command key hold
      # "cleanmymac"
      # "cloudapp" # screenshots
      # "contexts" # window switcher
      # "cord" # Windows remote desktop
      # "coscreen" # bidirectional screen sharing
      # "daisydisk" # disk usage visualizer
      # "dash" # documentation
      # "deepl" # TODO
      # "dropbox" # file sync
      # "ears" # switch audio input/output with keyboard
      # "electrum"
      # "figma"
      # "foobar2000" # music player
      # "fork" # Git GUI
      # "genymotion" # Android emulator
      # "github"
      # "gitify" # GitHub notifications
      # "gitkraken" "gitkraken-cli"
      # "hiddenbar" # hide menubar items
      # "hot" # CPU temperature
      # "inkscape"
      # "ioquake3"
      # "karabiner-elements" # keyboard shortcuts
      # "keepingyouawake" # inhibit sleep
      # "kindavim" # Vim keybinds everywhere
      # "knockknock" # anti-malware
      # "lapce"
      # "launchbar" # launcher TODO
      # "libreoffice"
      # "little-snitch" # firewall
      # "mailmate" # email client
      # "miniconda" # python environments
      # "mupdf" # pdf viewer # TODO crash
      # "mutify" # mic mute
      # "muzzle" # silence notifications when screensharing
      # "odrive" # file sync TODO
      # "parsec" # remote desktop
      # "polypane" # responsive browser
      # "raycast" # launcher
      # "shortcat" # launcher
      # "signal"
      # "sizzy" # responsive browser
      # "sloth" # lsof GUI
      # "soundsource" # per application audio control
      # "stats"
      # "swift-quit" # automatically quit apps when last window closed
      # "tableplus" # db GUI
      # "tailscale" # TODO services.tailscale
      # "textual" # IRC
      # "tuple" # bidirectional screen sharing # TODO
      # "ukelele" # keyboard layout
      # "unified-remote" # remote control
      # "utm" # virtual machines
      # "vlc" # video player
      # "vysor" # remote ios/android
      # "warp" # terminal
      # "webtorrent"
      # "wireshark" # TODO
    ];

    # TODO font-input
    # TODO font-iosevka{-aile,-curly,-etoile}
    # TODO git-delta
    # TODO macos-pasteboard
    # TODO piknik
    # TODO statsd
    # TODO taiko
    masApps = {
      "1Blocker" = 1365531024;
      "AdGuard for Safari" = 1440147259;
      "Archive Page Extension" = 6446372766;
      "darker" = 1637413102; # Safari dark mode
      "Hush" = 1544743900;
      "Hyperduck" = 6444667067;
      "Jiffy" = 1502527999; # GIF search in menu bar
      "Nitefall" = 1575190591; # Safari dark mode
      "Shareful" = 1522267256;
      "Slack for Desktop" = 803453959;
      "Super Agent" = 1568262835;
      "Tailscale" = 1475387142;
      "TestFlight" = 899247664;
      "Vimari" = 1480933944; # Safari Vim
      "Xcode" = 497799835;
      # "Actions" = 1586435171; # additional actions for the Shortcuts app
      # "Battery Indicator" = 1206020918;
      # "Black Out" = 1319884285; # redact parts of an image
      # "Camera Preview" = 1632827132;
      # "Command X" = 6448461551;
      # "Day Progress" = 6450280202;
      # "Element X - Secure messenger" = 1631335820;
      # "Lungo" = 1263070803; # keep awake
      # "MetaMask - Blockchain Wallet" = 1438144202;
      # "Noir – Dark Mode for Safari" = 1592917505;
      # "One Task" = 6465745322;
      # "Penguin - Plist Editor" = 1634084815;
      # "Recordia" = 1529006487; # quickly record audio
      # "SingleFile for Safari" = 6444322545;
      # "Speediness" = 1596706466; # internet speed test
      # "System Color Picker" = 1545870783;
      # "Velja" = 1607635845;# browser picker
    };

    brews = [
      "aichat" # ChatGPT
      "alerter" # notifications cli
      "amazon-ecs-cli"
      "asitop" # performance monitoring for Apple silicon
      "b2-tools" # Backblaze
      "blueutil" # bluetooth CLI
      "borkdude/brew/jet"
      "brightness" # macOS brigthness CLI
      "browser" # pipe HTML to browser
      "detox" # clean up filenames
      "difftastic"
      "docker-completion"
      "ffmpeg"
      "img2pdf"
      "ipfs"
      "jakehilborn/jakehilborn/displayplacer"
      "jqp"
      "launch" # CLI launcher
      "libiconv"
      "nethogs"
      "node"
      "nvm"
      "ocrmypdf"
      "pidof"
      "pkgxdev/made/pkgx" # Nix
      "postgresql"
      "pushtotalk" # mic mute
      "qsv" # CSV toolkit
      "schappim/ocr/ocr"
      "sleuthkit" # data forensics tool
      "switchaudio-osx"
      "torsocks"
      "util-linux" # setsid
      "viddy" # watch alternative
      # "askgitdev/treequery/treequery" # TODO
      # "csvtk" # CSV
      # "espanso" # TODO
      # "ext4fuse" # TODO
      # "felixkratz/formulae/svim" # macos vim everywhere
      # "fig" # terminal completion TODO
      # "hgrep" # grep with syntax highlighting TODO
      # "withgraphite/tap/graphite"
    ];
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
    programs.zsh.defaultKeymap = "viins";

    programs.zsh.initExtraFirst = ''
      autoload -Uz "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer"
    '';

    programs.zsh.initExtra = ''
      source ~/.zshrc.extra.zsh
    '';
  };

  system.activationScripts.postUserActivation.text = ''
    echo "disable boot sound"
    sudo /usr/sbin/nvram SystemAudioVolume=%80

    echo "show the ~/Library folder"
    chflags nohidden ~/Library

    echo "reduce menu bar whitespace"
    defaults write -g NSStatusItemSelectionPadding -int 12
    defaults write -g NSStatusItemSpacing -int 12
  '';
}
