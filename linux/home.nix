# Shared home-manager config for linux systems
# extraPackagesFile: optional file with additional packages (e.g. linux/packages-extra.nix)
{ config, inputs, extraPackagesFile ? null }:

{pkgs, ...}: {
  imports = [
    ../shared/rust-script-warmer.nix
    ./hyprland-auto-pin.nix
    inputs.vicinae.homeManagerModules.default
  ];

  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config = config.nixpkgs.config;
  nixpkgs.overlays = config.nixpkgs.overlays;

  home.packages =
    (import "${inputs.self}/packages.nix" pkgs)
    ++ (if extraPackagesFile != null then import extraPackagesFile pkgs else []);

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    initContent = "source ~/.config/zsh/rc.zsh";
  };

  services.playerctld.enable = true;
  services.wob.enable = true;
  services.vicinae = {
    enable = true;
    autoStart = true;
  };

  # Fix vicinae Qt environment - it hardcodes qt5ct which we don't use
  systemd.user.services.vicinae.Service.Environment = [
    "QT_QPA_PLATFORMTHEME=adwaita"
  ];

  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = let
    browser = "firefox";
  in {
    "application/pdf" = "org.pwmt.zathura.desktop";
    "image/jpeg" = "imv.desktop";
    "image/png" = "imv.desktop";
    "inode/directory" = "thunar.desktop";
    "text/html" = "${browser}.desktop";
    "text/plain" = "sublime_text.desktop";
    "video/mp4" = "mpv.desktop";
    "x-scheme-handler/http" = "${browser}.desktop";
    "x-scheme-handler/https" = "${browser}.desktop";
  };
  xdg.configFile."mimeapps.list".force = true;
}
