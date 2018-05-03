{ lib, ... }:

{
  home-manager.users.avo
    .xdg.configFile."mimeapps.list".text = lib.generators.toINI {} {
      "Default Applications" = {
        "x-scheme-handler/http"                                                   = "qutebrowser.desktop";
        "x-scheme-handler/https"                                                  = "qutebrowser.desktop";
        "x-scheme-handler/ftp"                                                    = "qutebrowser.desktop";
        "text/html"                                                               = "qutebrowser.desktop";
        "application/xhtml+xml"                                                   = "qutebrowser.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
        "application/pdf"                                                         = "zathura.desktop";
        "text/plain"                                                              = "emacs.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
        "application/xml"                                                         = "emacs.desktop";
      };
    };
}


