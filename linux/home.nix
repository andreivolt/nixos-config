# Shared home-manager config for linux systems
# extraPackagesFile: optional file with additional packages (e.g. linux/packages-extra.nix)
{ config, inputs, extraPackagesFile ? null }:

{pkgs, ...}: {
  imports = [
    ../shared/rust-script-warmer.nix
    ./hyprland-auto-pin.nix
    ./vicinae.nix
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

  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = let
    browser = "firefox";
    image-viewer = "swayimg.desktop";
    text-editor = "sublime_text.desktop";
  in {
    "application/epub+zip" = "org.pwmt.zathura.desktop";
    "application/pdf" = "org.pwmt.zathura.desktop";
    "image/avif" = image-viewer;
    "image/bmp" = image-viewer;
    "image/gif" = image-viewer;
    "image/heic" = image-viewer;
    "image/heif" = image-viewer;
    "image/jpeg" = image-viewer;
    "image/png" = image-viewer;
    "image/svg+xml" = image-viewer;
    "image/tiff" = image-viewer;
    "image/webp" = image-viewer;
    "inode/directory" = "thunar.desktop";
    "text/html" = "${browser}.desktop";
    "text/plain" = text-editor;
    "video/mp4" = "mpv.desktop";
    "x-scheme-handler/http" = "${browser}.desktop";
    "x-scheme-handler/https" = "${browser}.desktop";
  };
  xdg.configFile."mimeapps.list".force = true;
}
