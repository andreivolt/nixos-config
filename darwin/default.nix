{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../shared/clojure.nix
    ../shared/dnsmasq.nix
    ../shared/fonts.nix
    ../shared/gnupg.nix
    ../shared/moreutils-without-parallel.nix
    ./tor.nix
    ../shared/zsh-nix-completion.nix
    ./activity-monitor.nix
    ./auto-brightness.nix
    ./autoraise.nix
    ./boot-sound.nix
    ./chatgpt.nix
    ./default-browser.nix
    ./dock.nix
    ./file-associations.nix
    ./finder.nix
    ./google-drive.nix
    ./hammerspoon.nix
    ./homebrew
    ./htu.nix
    ./icloud.nix
    ./iina.nix
    ./interface.nix
    ./jumpcut.nix
    ./keyboard.nix
    ./menu-bar.nix
    ./power-management.nix
    ./privacy.nix
    ./remote-builders.nix
    ./screencapture.nix
    ./security.nix
    ./socks-proxy.nix
    ./spotlight.nix
    ./system-preferences.nix
    ./trackpad.nix
    ./wallpaper.nix
  ];

  users.users.andrei = {
    home = "/Users/andrei";
    description = "_";
  };

  programs.zsh.enable = true; # needed for setting path
  programs.zsh.enableCompletion = false; # slow

  environment.systemPackages = (import "${inputs.self}/packages.nix" pkgs) ++ (import ./packages.nix pkgs);

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

  # system.activationScripts.applySettings.text = lib.mkAfter ''
  #   echo 'apply settings immediately'
  #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
  # '';
}
