{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../shared/dnsmasq.nix
    ../shared/fonts.nix
    ../shared/gnupg.nix
    ../shared/moreutils-without-parallel.nix
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
    ./music-history.nix
    ./power-management.nix
    ./privacy.nix
    ./remote-builders.nix
    ./screencapture.nix
    ./security.nix
    ./socks-proxy.nix
    ./spotlight.nix
    ./system-preferences.nix
    ./telegram-archive.nix
    ./tor.nix
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

    programs.zsh = {
      enable = true; # TODO
      enableCompletion = false;
      initContent = "source ~/.zshrc.extra.zsh;";
    };
  };

  system.activationScripts.postActivation.text = ''
    sudo -u andrei /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
