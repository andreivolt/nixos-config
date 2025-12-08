# Shared home-manager config for linux systems
# extraPackagesFile: optional file with additional packages (e.g. linux/packages-extra.nix)
{ config, inputs, extraPackagesFile ? null }:

{pkgs, ...}: {
  imports = [
    ./hyprland/pin-auto.nix
    ./rofi.nix
    ./zathura.nix
  ];

  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config = config.nixpkgs.config;
  nixpkgs.overlays = config.nixpkgs.overlays;

  home.packages =
    (import "${inputs.self}/packages/core.nix" pkgs)
    ++ (import "${inputs.self}/packages/linux.nix" pkgs)
    ++ (import "${inputs.self}/packages/workstation.nix" pkgs)
    ++ (import "${inputs.self}/packages/gui.nix" pkgs)
    ++ (if extraPackagesFile != null then import extraPackagesFile pkgs else []);

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    initContent = "source ~/.config/zsh/rc.zsh";
  };

  services.playerctld.enable = true;
  services.wob = {
    enable = true;
    settings = {
      "" = {
        anchor = "bottom";
        margin = 100;
        height = 30;
        width = 300;
        border_size = 1;
        border_offset = 2;
        bar_padding = 2;
        background_color = "00000088";
        border_color = "ffffff99";
        bar_color = "ffffffcc";
        overflow_background_color = "00000088";
        overflow_border_color = "ff666699";
        overflow_bar_color = "ff6666cc";
      };
    };
  };

  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.dataFile."user-places.xbel".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE xbel>
    <xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
     <info>
      <metadata owner="http://www.kde.org">
       <kde_places_version>4</kde_places_version>
      </metadata>
     </info>
     <bookmark href="file:///home/andrei">
      <title>Home</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="user-home"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="file:///home/andrei/drive">
      <title>drive</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-cloud"/>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="file:///home/andrei/Downloads">
      <title>Downloads</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-downloads"/>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="remote:/">
      <title>Network</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-network"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="trash:/">
      <title>Trash</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="user-trash"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
    </xbel>
  '';
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = let
    browser = "firefox";
    image-viewer = "swayimg.desktop";
    text-editor = "sublime_text.desktop";
    video-player = "mpv.desktop";
    audio-player = "mpv.desktop";
  in {
    "application/epub+zip" = "org.pwmt.zathura.desktop";
    "application/pdf" = "org.pwmt.zathura.desktop";
    "audio/aac" = audio-player;
    "audio/flac" = audio-player;
    "audio/mp4" = audio-player;
    "audio/mpeg" = audio-player;
    "audio/ogg" = audio-player;
    "audio/wav" = audio-player;
    "audio/webm" = audio-player;
    "audio/x-wav" = audio-player;
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
    "video/mp4" = video-player;
    "video/mpeg" = video-player;
    "video/ogg" = video-player;
    "video/quicktime" = video-player;
    "video/webm" = video-player;
    "video/x-matroska" = video-player;
    "x-scheme-handler/http" = "${browser}.desktop";
    "x-scheme-handler/https" = "${browser}.desktop";
  };
  xdg.configFile."mimeapps.list".force = true;

  # Custom desktop files with proper MimeType for Dolphin/KDE
  xdg.desktopEntries = {
    swayimg = {
      name = "Swayimg";
      comment = "Image viewer for Wayland";
      exec = "swayimg %U";
      icon = "swayimg";
      terminal = false;
      categories = ["Graphics" "Viewer"];
      mimeType = ["image/jpeg" "image/png" "image/gif" "image/bmp" "image/webp" "image/avif" "image/heic" "image/heif" "image/tiff" "image/svg+xml"];
    };
  };
}
