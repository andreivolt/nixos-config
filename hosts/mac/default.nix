{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../shared/sops.nix
    ../../shared/sops-home.nix
    ../../shared/ssh-client.nix
    ../../shared/aria2.nix
    ../../shared/bat
    ../../shared/btop.nix
    ../../shared/cargo.nix
    ../../shared/curl.nix
    ../../shared/dircolors.nix
    ../../shared/direnv.nix
    ../../shared/dnsmasq.nix
    ../../shared/fonts.nix
    ../../shared/delta.nix
    ../../shared/gh.nix
    ../../shared/git
    ../../shared/ghostty
    ../../shared/glab.nix
    ../../shared/gnupg.nix
    ../../shared/htop.nix
    ../../shared/hushlogin.nix
    ../../shared/mpv
    ../../shared/npm.nix
    ../../shared/npm-tools.nix
    ../../shared/uv-tools.nix
    ../../shared/parallel.nix
    ../../shared/pry
    ../../shared/readline.nix
    ../../shared/ripgrep.nix
    ../../shared/rubocop.nix
    ../../shared/rustfmt.nix
    ../../shared/tmux.nix
    ../../shared/wezterm
    ../../shared/zed
    ../../shared/zsh
    ../../darwin/lan-mouse.nix
    ./activity-monitor.nix
    ./alt-tab.nix
    ./auto-brightness.nix
    ./boot-sound.nix
    ./chatgpt.nix
    ./claude-command-monitor.nix
    ./default-browser.nix
    ./dock.nix
    ./file-associations.nix
    ./finder.nix
    ./google-drive.nix
    ./hammerspoon.nix
    ./homebrew
    ./host-opener.nix
    ./chrome-history.nix
    ../../shared/chromium-extensions.nix
    ../../shared/ff2mpv.nix
    ../../shared/dearrow.nix
    ./icloud.nix
    ./iina.nix
    ./interface.nix
    ./keyboard.nix
    ./menu-bar.nix
    ./music-history.nix
    ./power-management.nix
    ./privacy.nix
    ./remote-builders.nix
    ./screencapture.nix
    ./security.nix
    ./socks-proxy.nix
    ./ssh.nix
    ./spotlight.nix
    ./system-preferences.nix
    ./telegram-archive.nix
    ./telegram-open.nix
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

  environment.systemPackages =
    (import "${inputs.self}/packages/core.nix" pkgs)
    ++ (import "${inputs.self}/packages/darwin.nix" pkgs)
    ++ (import "${inputs.self}/packages/gui.nix" pkgs);

  home-manager.useGlobalPkgs = true;
  home-manager.sharedModules = [
    inputs.mac-app-util.homeManagerModules.default
  ];

  home-manager.users.andrei = {pkgs, ...}: {
    home.stateVersion = "23.11";
    home.enableNixpkgsReleaseCheck = false;

    programs.man.generateCaches = true;
  };

  system.activationScripts.postActivation.text = ''
    sudo -u andrei /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
