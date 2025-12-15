# Swayimg image viewer configuration
{ ... }: {
  xdg.configFile."swayimg/config".text = ''
    [general]
    size = image
    overlay = no

    [viewer]
    scale = optimal

    [font]
    name = Roboto
    size = 14

    [info]
    show = no
  '';

  xdg.desktopEntries.swayimg = {
    name = "Swayimg";
    comment = "Image viewer for Wayland";
    exec = "swayimg %U";
    icon = "swayimg";
    terminal = false;
    categories = ["Graphics" "Viewer"];
    mimeType = ["image/jpeg" "image/png" "image/gif" "image/bmp" "image/webp" "image/avif" "image/heic" "image/heif" "image/tiff" "image/svg+xml"];
  };
}
