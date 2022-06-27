{ config, lib, pkgs, ... }:

{
  imports =
    [<home-manager/nix-darwin>] ++ [
      # /Users/avo/drive/nixos-config/modules/gnupg.nix # TODO
      # /Users/avo/drive/nixos-config/modules/ngrok.nix # TODO
      /Users/avo/drive/nixos-config/modules/alacritty/alacritty.nix
      /Users/avo/drive/nixos-config/modules/aria2.nix
      /Users/avo/drive/nixos-config/modules/bat.nix
      /Users/avo/drive/nixos-config/modules/clojure # TODO
      /Users/avo/drive/nixos-config/modules/clojure/boot
      /Users/avo/drive/nixos-config/modules/clojure/rebel-readline.nix
      /Users/avo/drive/nixos-config/modules/command-not-found.nix
      /Users/avo/drive/nixos-config/modules/curl.nix
      /Users/avo/drive/nixos-config/modules/direnv.nix
      /Users/avo/drive/nixos-config/modules/fonts.nix
      /Users/avo/drive/nixos-config/modules/grep.nix
      /Users/avo/drive/nixos-config/modules/less.nix
      /Users/avo/drive/nixos-config/modules/mac-apps-gui.nix
      /Users/avo/drive/nixos-config/modules/mac-dock.nix
      /Users/avo/drive/nixos-config/modules/mac-screenshots.nix
      /Users/avo/drive/nixos-config/modules/moreutils-without-parallel.nix
      /Users/avo/drive/nixos-config/modules/nix.nix
      /Users/avo/drive/nixos-config/modules/readline/inputrc.nix
      /Users/avo/drive/nixos-config/modules/ripgrep.nix
      /Users/avo/drive/nixos-config/modules/vim-as-manpager.nix
      /Users/avo/drive/nixos-config/modules/zsh-autosuggest.nix
    ] ++ [./macos-defaults.nix];

  services.lorri.enable = true; # nix direnv

  services.redis.enable = true;
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
  };

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

  # resolve *.test to localhost
  services.dnsmasq = {
    enable = true;
    addresses.test = "127.0.0.1";
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
    # swapLeftCommandAndLeftAlt = true;
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false;
  };

  launchd.daemons.nginx = with pkgs; {
    command = "${nginx}/bin/nginx";
    path = [nginx];
    serviceConfig = {
      KeepAlive = true;
    };
  };

  home-manager.users.avo = { pkgs, config, ... }: {
    home.sessionVariables.EDITOR = "nvim";

    # home.activation = {
    #   aliasApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #   ln -sfn $genProfilePath/home-path/Applications "$HOME/Applications/Home Manager Applications"
    #   '';
    # };

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    programs.zsh.enableCompletion = false;

    programs.zsh.enable = true; # TODO
    # programs.zsh.enableSyntaxHighlighting = true;

    # edit without rebuilding
    programs.zsh.initExtra = ''
      source ~/.zshrc.extra.zsh;
    '';

    programs.zsh.plugins = with pkgs; [
      {
        name = "autopair";
        file = "autopair.zsh";
        src = fetchFromGitHub {
          owner = "hlissner";
          repo = "zsh-autopair";
          rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1";
          sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
        };
      }
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.2.0";
          sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
        };
      }
    ];

    programs.zsh.history = rec {
      size = 99999;
      save = size;
    };

    programs.zsh.shellAliases = import /Users/avo/drive/nixos-config/aliases.nix;

    programs.zsh.shellGlobalAliases = import /Users/avo/drive/nixos-config/modules/zsh-global-aliases.nix;
  };

  environment.systemPackages =
    with pkgs; let
      comma = (import (fetchFromGitHub {
        owner = "nix-community";
        repo = "comma";
        rev = "v1.2.0";
        sha256 = "fZ/Rb//cVZBgQ99/vbs7BcFn+qO6D077lTrZAWR7b/Q=";
      })).default;
    in
      (import /Users/avo/drive/nixos-config/packages.nix pkgs) ++
      (import /Users/avo/drive/nixos-config/modules/mac-packages.nix pkgs);

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

  launchd.daemons.ipfs = {
    script = "${pkgs.ipfs}/bin/ipfs daemon";

    serviceConfig = {
      Label = "ipfs";
      RunAtLoad = true;
      KeepAlive.NetworkState = true;
    };
  };

  homebrew = {
    enable = true;
    cleanup = "zap";
    autoUpdate = true;
    # TODO alfred
    # TODO amphetamine
    # TODO contexts
    # TODO csv2xlsx
    # TODO darksky-weather
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
      "alerter" # notifications cli
      "brightness" # macos brigthness cli
      "browser" # pipe html to browser
      "chruby" # ruby
      "darksky-weather" # weather cli
      "docker-completion"
      "federico-terzi/espanso/espanso" # TODO
      "felixkratz/formulae/svim" # macos vim everywhere
      "fig" # terminal completion
      "helm" # kubernetes
      "imagemagick@6"
      "ipfs"
      "iproute2mac"
      "jakehilborn/jakehilborn/displayplacer"
      "libyaml" # ruby
      "lua-language-server" # lua lsp
      "mupdf" # pdf viewer
      "navi" # cheatsheet cli
      "nethogs"
      "nvm" # nodejs
      "pidof"
      "pngpaste"
      "postgresql"
      "difftastic"
      "reattach-to-user-namespace" # tmate
      "robotsandpencils/made/xcodes"
      "ruby-build"
      "ruby-install"
      "switchaudio-osx"
      "trash-cli"
      "util-linux" # setsid
      "v8@3.15" # therubyracer
      "zsh-fast-syntax-highlighting"
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
    ];
    extraConfig = ''
      brew "tor", restart_service: true
      brew "mopidy/mopidy/mopidy", args: ["HEAD"]
    '';
  };
}
