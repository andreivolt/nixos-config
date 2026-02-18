{pkgs, ...}:
let
  colors = import ../shared/colors.nix;
  ui = import ../shared/ui.nix;
  # Strip alpha from ui.bg for solid color contexts
  bgSolid = builtins.substring 0 7 colors.ui.bg;

  # Shared CSS for GTK accent color overrides (identical for gtk3/gtk4)
  accentCss = ''
    /* Obsidian Aurora accent overrides */
    @define-color accent_color ${colors.accent.primary};
    @define-color accent_bg_color ${colors.accent.primary};
    @define-color accent_fg_color ${bgSolid};

    /* Selection colors */
    selection, *:selected {
      background-color: alpha(${colors.accent.primary}, 0.3);
    }

    /* Focus rings */
    *:focus-visible {
      outline-color: ${colors.accent.primary};
    }

    /* Buttons */
    button.suggested-action {
      background-color: ${colors.accent.primary};
      color: ${bgSolid};
    }

    /* Links */
    link, *:link {
      color: ${colors.accent.primary};
    }

    /* Switches when checked */
    switch:checked {
      background-color: ${colors.accent.primary};
    }

    /* Progress bars */
    progressbar > trough > progress {
      background-color: ${colors.accent.primary};
    }

    /* Scale/slider highlight */
    scale > trough > highlight {
      background-color: ${colors.accent.primary};
    }
  '';
in {
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
    GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
  };

  home-manager.users.andrei = {
    home.packages = with pkgs; [
      andrei.phosphor-icon-theme
      papirus-icon-theme
      noto-fonts
      gsettings-desktop-schemas
    ];

    gtk = {
      enable = true;
      # Use Adwaita - color-scheme handles dark/light mode
      theme.name = "Adwaita";
      iconTheme.name = "Phosphor";
      font = {
        name = ui.fontFamily;
        size = ui.fontSizePt;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk3.extraCss = accentCss;
      gtk4.extraCss = accentCss;
    };

    # Set color-scheme for apps that use XDG Settings portal (Chromium, etc.)
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        monospace-font-name = "Pragmasevka Nerd Font Light 10";
      };
    };
  };
}
