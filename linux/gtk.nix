{pkgs, ...}: {
  # Ensure gsettings schemas are available system-wide
  environment.systemPackages = with pkgs; [
    gsettings-desktop-schemas
    glib  # For gsettings command
  ];

  # Required for gsettings to find schemas
  programs.dconf.enable = true;

  # Set GSETTINGS_SCHEMA_DIR so gsettings can find schemas
  environment.sessionVariables = {
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };

  home-manager.users.andrei = {
    home.packages = with pkgs; [
      papirus-icon-theme
      noto-fonts
      gsettings-desktop-schemas
    ];

    gtk = {
      enable = true;
      # Use Adwaita - color-scheme handles dark/light mode
      theme.name = "Adwaita";
      iconTheme.name = "Papirus-Dark";
      font = {
        name = "Roboto";
        size = 10;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      # Custom CSS for warm red accent colors
      gtk3.extraCss = ''
        /* Obsidian Aurora accent overrides */
        @define-color accent_color #b85555;
        @define-color accent_bg_color #b85555;
        @define-color accent_fg_color #0a0a0a;

        /* Selection colors */
        selection, *:selected {
          background-color: alpha(#b85555, 0.3);
        }

        /* Focus rings */
        *:focus-visible {
          outline-color: #b85555;
        }

        /* Buttons */
        button.suggested-action {
          background-color: #b85555;
          color: #0a0a0a;
        }

        /* Links */
        link, *:link {
          color: #b85555;
        }

        /* Switches when checked */
        switch:checked {
          background-color: #b85555;
        }

        /* Progress bars */
        progressbar > trough > progress {
          background-color: #b85555;
        }

        /* Scale/slider highlight */
        scale > trough > highlight {
          background-color: #b85555;
        }
      '';
      gtk4.extraCss = ''
        /* Obsidian Aurora accent overrides */
        @define-color accent_color #b85555;
        @define-color accent_bg_color #b85555;
        @define-color accent_fg_color #0a0a0a;

        /* Selection colors */
        selection, *:selected {
          background-color: alpha(#b85555, 0.3);
        }

        /* Focus rings */
        *:focus-visible {
          outline-color: #b85555;
        }

        /* Buttons */
        button.suggested-action {
          background-color: #b85555;
          color: #0a0a0a;
        }

        /* Links */
        link, *:link {
          color: #b85555;
        }

        /* Switches when checked */
        switch:checked {
          background-color: #b85555;
        }

        /* Progress bars */
        progressbar > trough > progress {
          background-color: #b85555;
        }

        /* Scale/slider highlight */
        scale > trough > highlight {
          background-color: #b85555;
        }
      '';
    };

    # Set color-scheme for apps that use XDG Settings portal (Chromium, etc.)
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
