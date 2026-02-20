# Default applications for MIME types
{ pkgs, ... }:
let
  browser = "chromium-browser";
  image-viewer = "swayimg.desktop";
  text-editor = "sublime_text.desktop";
  video-player = "mpv.desktop";
  audio-player = "mpv.desktop";
in {
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
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
    "inode/directory" = "pcmanfm.desktop";
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
}
