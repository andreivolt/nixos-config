# Zathura document viewer configuration
{
  programs.zathura = {
    enable = true;
    options = {
      font = "Roboto 11";
      recolor = true;
    };
  };

  # Custom desktop file with proper MimeType for file managers
  xdg.desktopEntries.zathura = {
    name = "Zathura";
    comment = "A minimalistic document viewer";
    exec = "zathura %U";
    icon = "org.pwmt.zathura";
    terminal = false;
    categories = ["Office" "Viewer"];
    mimeType = ["application/pdf" "application/epub+zip" "application/oxps" "application/x-fictionbook"];
  };
}
