# Custom desktop entries
{ ... }: {
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
