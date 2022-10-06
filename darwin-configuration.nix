{ config, lib, pkgs, ... }:

{
  imports =
    [<home-manager/nix-darwin>] ++ [
      # ./modules/gnupg.nix # TODO
      # ./modules/ngrok.nix # TODO
      ./modules/alacritty/alacritty.nix
      ./modules/aria2.nix
      ./modules/bat.nix
      ./modules/clojure # TODO
      ./modules/clojure/boot
      ./modules/clojure/rebel-readline.nix
      ./modules/command-not-found.nix
      ./modules/curl.nix
      ./modules/direnv.nix
      # ./modules/fonts.nix
      ./modules/grep.nix
      ./modules/less.nix
      ./modules/mac_apps-gui.nix
      ./modules/mac_dock.nix
      ./modules/mac_ipfs.nix
      ./modules/mac_map-caps-to-esc.nix
      ./modules/mac_map-test-tld-to-localhost.nix
      ./modules/mac_nginx.nix
      ./modules/mac_postgres.nix
      ./modules/mac_screenshots.nix
      ./modules/moreutils-without-parallel.nix
      ./modules/nix.nix
      ./modules/readline/inputrc.nix
      ./modules/ripgrep.nix
      ./modules/ruby.nix
      ./modules/vim-as-manpager.nix
      ./modules/zsh-autosuggest.nix
    ] ++ [./macos-defaults.nix];

  services.lorri.enable = true; # nix direnv

  services.redis.enable = true;

  users.users.avo = {
    name = "avo";
    home = "/Users/avo";
  };

  system.defaults.NSGlobalDomain = {
    "com.apple.trackpad.enableSecondaryClick" = true;
    "com.apple.trackpad.trackpadCornerClickBehavior" = 1;

    AppleFontSmoothing = 0;

    AppleShowAllExtensions = true;

    AppleShowScrollBars = "Always";

    NSNavPanelExpandedStateForSaveMode = true;

    # autohide menu bar
    _HIHideMenuBar = true;

    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
  };

  # system.defaults.universalaccess.reduceTransparency = true; # TODO

  system.defaults.trackpad = {
    TrackpadRightClick = true;
    Clicking = true;
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false;
  };

  # system.keyboard.swapLeftCommandAndLeftAlt = true; # TODO

  home-manager.users.avo = import ./modules/zsh.nix;

  environment.systemPackages =
    with pkgs; let
      comma = (import (fetchFromGitHub {
        owner = "nix-community";
        repo = "comma";
        rev = "v1.2.0";
        sha256 = "fZ/Rb//cVZBgQ99/vbs7BcFn+qO6D077lTrZAWR7b/Q=";
      })).default;
    in
      [
        Hyperbeam # cobrowsing
      ] ++
      (import /Users/avo/drive/nixos-config/packages.nix pkgs) ++
      (import /Users/avo/drive/nixos-config/modules/mac_packages.nix pkgs);

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = let
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable =
        let nixpkgs-unstable-src = fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
        in import nixpkgs-unstable-src { };
      };
  in [
    (import ./mac-apps.nix)
    nixpkgsUnstable
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
  # programs.zsh.enableFzfHistory = true;
  programs.zsh.enableFzfGit = true;
  # programs.zsh.enableFzfCompletion = true;
  # programs.zsh.enableBashCompletion = true;

  programs.zsh.enableCompletion = false;
  # home-manager.users.avo.programs.zsh.enableCompletion = false;
  programs.zsh.interactiveShellInit = builtins.readFile ~/.zsh.d/compinit-speed-fix.zsh;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
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
    # TODO quicksilver
    # TODO statsd
    # TODO taiko

    brews= [
      "ffmpeg"
      "jqp"
      "alerter" # notifications cli
      "brightness" # macos brigthness cli
      "browser" # pipe html to browser
      "darksky-weather" # weather cli
      "docker-completion"
      "federico-terzi/espanso/espanso" # TODO
      "felixkratz/formulae/svim" # macos vim everywhere
      # "fig" # terminal completion TODO
      "imagemagick@6"
      "ipfs"
      "iproute2mac"
      "jakehilborn/jakehilborn/displayplacer"
      "libyaml" # ruby
      "lua-language-server" # lua lsp
      "mupdf" # pdf viewer
      "nethogs"
      "nvm" # nodejs
      "dmd" # d compiler
      "pidof"
      "postgresql"
      "difftastic"
      "robotsandpencils/made/xcodes"
      "switchaudio-osx"
      "trash-cli"
      "util-linux" # setsid
      "blueutil" # bluetooth cli

      "pushtotalk" # mic mute
      # "hgrep" # grep with syntax highlighting TODO
      # "askgitdev/treequery/treequery" # TODO
      # "withgraphite/tap/graphite"
    ];
    # masApps = { Xcode = 497799835; };
    taps = [
      "federico-terzi/espanso"
      "felixkratz/formulae"
      "homebrew/autoupdate"
      "homebrew/bundle"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/core"
      "homebrew/services"
      "jakehilborn/jakehilborn"
      "mopidy/mopidy"
      "robotsandpencils/made"
      "withgraphite/tap"
      "noahgorstein/tap" # jqp
      "yulrizka/tap" # pushtotalk
    ];
    extraConfig = ''
      brew "tor", restart_service: true
      brew "mopidy/mopidy/mopidy", args: ["HEAD"]
    '';
  };
}
