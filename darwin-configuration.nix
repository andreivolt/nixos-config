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
    ./modules/darwin/activity-monitor.nix
    ./modules/darwin/autoraise.nix
    ./modules/darwin/chatgpt.nix
    ./modules/darwin/dock.nix
    ./modules/darwin/file-associations.nix
    ./modules/darwin/finder.nix
    ./modules/darwin/google-drive.nix
    ./modules/darwin/hammerspoon.nix
    ./modules/darwin/htu.nix
    ./modules/darwin/iina.nix
    ./modules/darwin/interface.nix
    ./modules/darwin/jumpcut.nix
    ./modules/darwin/keyboard.nix
    ./modules/darwin/privacy.nix
    ./modules/darwin/screencapture.nix
    ./modules/darwin/security.nix
    ./modules/darwin/socks-proxy.nix
    ./modules/darwin/spotlight.nix
    ./modules/darwin/system-preferences.nix
    ./modules/darwin/tor.nix
    ./modules/darwin/trackpad.nix
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

  # TODO Safari full URL
  # system.defaults.CustomUserPreferences."com.apple.Safari".ShowFullURLInSmartSearchField = true;

  # TODO iCloud disable auto sync
  # defaults write "com.apple.bird" "optimize-storage" '0'

  # TODO reduce transparency
  # system.defaults.universalaccess.reduceTransparency = true;

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
