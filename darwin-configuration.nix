{ config, lib, pkgs, ... }:

{
  imports =
    [<home-manager/nix-darwin>] ++ [
      # ./modules/mac_postgres.nix
      # ./modules/ngrok.nix # TODO
      ./modules/bat.nix
      ./modules/clojure
      ./modules/clojure/boot
      ./modules/clojure/rebel-readline.nix
      ./modules/command-not-found.nix
      ./modules/curl.nix
      ./modules/direnv.nix
      # ./modules/git.nix
      ./modules/grep.nix
      # ./modules/htu_autobackup.nix
      ./modules/less.nix
      ./modules/mac_apps-gui.nix
      ./modules/mac_dock.nix
      ./modules/mac_finder.nix
      ./modules/mac_fonts.nix
      ./modules/mac_ipfs.nix
      ./modules/mac_keyboard.nix
      ./modules/mac_map-caps-to-esc.nix
      ./modules/mac_map-test-tld-to-localhost.nix
      ./modules/mac_nginx.nix
      ./modules/mac_screenshots.nix
      ./modules/mac_trackpad.nix
      ./modules/moreutils-without-parallel.nix
      ./modules/nix.nix
      ./modules/playwright.nix
      ./modules/readline/inputrc.nix
      ./modules/ripgrep.nix
      ./modules/ruby.nix
      ./modules/zsh/fzf.nix
    ] ++ [./macos-defaults.nix];

  networking.hostName = "mac";

  # programs.gnupg.agent.enable
  # programs.gnupg.agent.enableSSHSupport

  # environment.shellInit = ''
  #   export PATH="$HOME/.local/bin:$PATH"
  # '';

  users.users.andrei = {
    name = "andrei";
    home = "/Users/andrei";
  };

  services.lorri.enable = true; # Nix direnv

  system.defaults.NSGlobalDomain = {
    "com.apple.sound.beep.feedback" = 0; # feedback sound when system volume changes
    # "com.apple.sound.beep.volume" = 0.5;
    # _HIHideMenuBar = true; # autohide menu bar
    AppleFontSmoothing = 0;
    AppleInterfaceStyle = "Dark";
    AppleKeyboardUIMode = 3; # enable full keyboard access for controls
    AppleScrollerPagingBehavior = true; # jump to the spot that's clicked on the scroll bar
    AppleShowAllExtensions = true;
    AppleShowScrollBars = "Always";
    NSNavPanelExpandedStateForSaveMode = true;
  };

  # system.defaults.universalaccess.reduceTransparency = true; # TODO

  # home-manager.users.avo = import ./modules/zsh.nix;

  home-manager.useGlobalPkgs = true; # Use the global pkgs that is configured via the system level nixpkgs options. This saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH, which is otherwise used for importing Nixpkgs.

  environment.systemPackages =
    with pkgs; [
      PrettyClean
      # WriteMage
    ] ++
    (import "/Users/andrei/drive/nixos-config/packages.nix" pkgs);

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = let
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable = import <nixpkgs-unstable> {};
    };
  in [
    (import ./mac-apps.nix)
    nixpkgsUnstable
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
  programs.zsh.enableFzfHistory = true;
  programs.zsh.enableFzfGit = true;
  # programs.zsh.enableFzfCompletion = true;
  # programs.zsh.enableBashCompletion = true;

  programs.zsh.enableCompletion = false;
  # home-manager.users.avo.programs.zsh.enableCompletion = false;
  # programs.zsh.interactiveShellInit = builtins.readFile ~/.zsh.d/compinit-speed-fix.zsh;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  homebrew = {
    enable = true;
    # global.brewfile = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    # TODO alfred
    # TODO amphetamine
    # TODO contexts
    # TODO csv2xlsx
    # TODO font-input
    # TODO font-iosevka{-aile,-curly,-etoile}
    # TODO git-delta
    # TODO lifxstyle
    # TODO macos-pasteboard
    # TODO oni2
    # TODO piknik
    # TODO pyenv
    # TODO statsd
    # TODO taiko
    masApps = {
      "FBReader: ePub and fb2 reader" = 1067172178;
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
      # "Lungo" = 1263070803; # keep awake
      # "MetaMask - Blockchain Wallet" = 1438144202;
      # "Noir – Dark Mode for Safari" = 1592917505;
      # "One Task" = 6465745322;
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
      # "csvtk" # CSV
      "detox" # clean up filenames
      "difftastic"
      "docker-completion"
      "ffmpeg"
      "sleuthkit" # data forensics tool
      "img2pdf"
      "ipfs"
      "jakehilborn/jakehilborn/displayplacer"
      "jqp"
      "launch" # CLI launcher
      "libiconv"
      "lua-language-server" # Lua LSP
      "m-cli" # macOS system CLI
      "nethogs"
      "node"
      "nvm"
      "ocrmypdf"
      "pidof"
      "pkgxdev/made/pkgx" # Nix
      "postgresql"
      "pushtotalk" # mic mute
      "qsv" # ultra-fast csv toolkit
      "neovide"
      "schappim/ocr/ocr"
      "switchaudio-osx"
      "torsocks"
      "util-linux" # setsid
      "viddy" # notifications CLI
      # "askgitdev/treequery/treequery" # TODO
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
      # "mopidy/mopidy"
      # "withgraphite/tap"
    ];
    extraConfig = ''
      brew "tor", restart_service: true
      # brew "mopidy/mopidy/mopidy", args: ["HEAD"]
    '';
  };

  home-manager.users.andrei = { pkgs, ... }: rec {
    home.stateVersion = "23.11";

    home.file.".pydistutils.cfg".text = ''
      [build_ext]
      include_dirs=${pkgs.portaudio}/include/
      library_dirs=${pkgs.portaudio}/lib/
    '';

    home.file.".duti" = {
      text = ''
        com.colliderli.iina webm all
        com.colliderli.iina aac all
        com.colliderli.iina mp4 all
        com.mimestream.Mimestream mailto
      '';
      onChange = "${pkgs.duti}/bin/duti ~/.duti";
    };

    programs.zsh.enableCompletion = false;
    programs.zsh.enable = true; # TODO
    programs.zsh.defaultKeymap = "viins";

    programs.zsh.initExtra = "source ~/.zshrc.extra.zsh;";
  };

  environment.darwinConfig = "$HOME/drive/nixos-config/darwin-configuration.nix";

  # services.nix-daemon.enable = true;
}
