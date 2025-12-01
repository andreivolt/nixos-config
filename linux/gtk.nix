{pkgs, ...}: {
  # Ensure gsettings schemas are available system-wide
  environment.systemPackages = with pkgs; [
    gsettings-desktop-schemas
    glib  # For gsettings command
  ];

  # Required for gsettings to find schemas
  programs.dconf.enable = true;

  # Set GSETTINGS_SCHEMA_DIR so gsettings can find schemas
  # Google API keys for Chromium sign-in/sync
  environment.sessionVariables = {
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };

  home-manager.users.andrei = {
    home.packages = with pkgs; [
      tela-icon-theme
      noto-fonts
      gsettings-desktop-schemas
    ];

    gtk = {
      enable = true;
      theme.name = "Breeze-Dark";
      iconTheme.name = "Tela-dark";
      font = {
        name = "Noto Sans";
        size = 10;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    # Set color-scheme for apps that use XDG Settings portal (Chromium, etc.)
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
