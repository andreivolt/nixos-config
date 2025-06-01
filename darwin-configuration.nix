{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./modules/clojure.nix
    ./modules/fonts.nix
    ./modules/gnupg.nix
    ./modules/dnsmasq.nix
    ./modules/homebrew.nix
    ./modules/darwin/activity-monitor.nix
    ./modules/darwin/auto-brightness.nix
    ./modules/darwin/autoraise.nix
    ./modules/darwin/boot-sound.nix
    ./modules/darwin/chatgpt.nix
    ./modules/darwin/default-browser.nix
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
    ./modules/darwin/menu-bar.nix
    ./modules/darwin/power-management.nix
    ./modules/darwin/privacy.nix
    ./modules/darwin/screencapture.nix
    ./modules/darwin/security.nix
    ./modules/darwin/socks-proxy.nix
    ./modules/darwin/spotlight.nix
    ./modules/darwin/system-preferences.nix
    ./modules/darwin/tor.nix
    ./modules/darwin/trackpad.nix
    ./modules/darwin/wallpaper.nix
    ./modules/moreutils-without-parallel.nix
    ./modules/zsh-nix-completion.nix
  ];

  networking.hostName = "mac";
  system.stateVersion = 4;
  system.primaryUser = "andrei";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = false; # using Determinate Nix
  # services.lorri.enable = true;

  users.users.andrei = {
    home = "/Users/andrei";
    description = "_";
  };

  programs.zsh.enable = true; # needed for setting path
  programs.zsh.enableCompletion = false; # slow

  environment.systemPackages = import "${inputs.self}/packages.nix" pkgs;

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

  # TODO Safari full URL
  # system.defaults.CustomUserPreferences."com.apple.Safari".ShowFullURLInSmartSearchField = true;

  # TODO iCloud disable auto sync
  # defaults write "com.apple.bird" "optimize-storage" '0'

  # TODO reduce transparency
  # system.defaults.universalaccess.reduceTransparency = true;

  # TODO: apply settings immediately
  # system.activationScripts.postActivation.text = ''
  #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  # '';
}
