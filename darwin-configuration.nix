{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./shared/clojure.nix
    ./darwin/activity-monitor.nix
    ./darwin/apply-settings.nix
    ./darwin/auto-brightness.nix
    ./darwin/autoraise.nix
    ./darwin/boot-sound.nix
    ./darwin/chatgpt.nix
    ./darwin/default-browser.nix
    ./darwin/dock.nix
    ./darwin/file-associations.nix
    ./darwin/finder.nix
    ./darwin/google-drive.nix
    ./darwin/hammerspoon.nix
    ./darwin/htu.nix
    ./darwin/icloud.nix
    ./darwin/iina.nix
    ./darwin/interface.nix
    ./darwin/jumpcut.nix
    ./darwin/keyboard.nix
    ./darwin/menu-bar.nix
    ./darwin/power-management.nix
    ./darwin/privacy.nix
    ./darwin/screencapture.nix
    ./darwin/security.nix
    ./darwin/socks-proxy.nix
    ./darwin/spotlight.nix
    ./darwin/system-preferences.nix
    ./darwin/tor.nix
    ./darwin/trackpad.nix
    ./darwin/wallpaper.nix
    ./shared/dnsmasq.nix
    ./shared/fonts.nix
    ./shared/gnupg.nix
    ./darwin/homebrew
    ./shared/moreutils-without-parallel.nix
    ./shared/zsh-nix-completion.nix
  ];

  networking.hostName = "mac";
  system.stateVersion = 4;
  system.primaryUser = "andrei";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = false; # using Determinate Nix

  users.users.andrei = {
    home = "/Users/andrei";
    description = "_";
  };

  programs.zsh.enable = true; # needed for setting path
  programs.zsh.enableCompletion = false; # slow

  environment.systemPackages = (import "${inputs.self}/packages.nix" pkgs) ++ (import ./darwin/packages.nix pkgs);

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
}
