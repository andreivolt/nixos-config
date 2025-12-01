{pkgs, ...}: {
  # Ensure gsettings schemas are available system-wide
  environment.systemPackages = with pkgs; [
    gsettings-desktop-schemas
    glib  # For gsettings command
  ];

  # Required for gsettings to find schemas
  programs.dconf.enable = true;

  # Set GSETTINGS_SCHEMA_DIR so gsettings can find schemas
  # NIXOS_OZONE_WL enables native Wayland for Electron/Chromium apps
  environment.sessionVariables = {
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
    NIXOS_OZONE_WL = "1";
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
