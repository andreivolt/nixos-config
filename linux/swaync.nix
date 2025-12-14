{ config, lib, pkgs, ... }:
let
  colors = import ../shared/colors.nix;
  # Strip alpha from ui.bg for solid color contexts
  bgSolid = builtins.substring 0 7 colors.ui.bg;
in {
  # Install swaync package
  environment.systemPackages = [ pkgs.swaynotificationcenter ];

  # SwayNotificationCenter service - Obsidian Aurora theme
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.swaync = {
      enable = true;
      settings = {
        cssPriority = "user";
      };
      style = ''
        * {
          font-family: Roboto, sans-serif;
          border-radius: 2px;
        }

        .control-center {
          border-radius: 0;
          background: ${bgSolid};
          border: none;
          padding: 0;
        }

        .control-center-list {
          padding: 8px;
          margin: 0;
        }

        .notification-row {
          margin: 4px 0;
          padding: 0;
        }

        .notification {
          border-radius: 2px;
          padding: 0;
        }

        .notification-background {
          border-radius: 2px;
          border: none;
          padding: 12px;
          background: ${colors.ui.bgAlt};
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.7);
        }

        .notification-content {
          border-radius: 2px;
          padding: 0;
          margin: 0;
        }

        .control-center .notification-row .notification-background {
          border-radius: 2px;
          background: ${colors.ui.bgAlt};
          border: none;
        }

        .notification-group {
          border-radius: 2px;
        }

        .notification-group-headers {
          border-radius: 2px;
          background: transparent;
        }

        .notification-group-headers > button {
          border-radius: 2px;
          background: ${colors.ui.bgAlt};
          border: none;
          padding: 4px 8px;
          color: ${colors.ui.fgDim};
        }

        .notification-group-collapse-button,
        .notification-group-close-all-button {
          border-radius: 2px;
          background: ${colors.ui.bgAlt};
          border: none;
        }

        .image {
          border-radius: 2px;
        }

        .widget-title {
          border-radius: 0;
          background: transparent;
          color: ${colors.ui.fgDim};
          padding: 4px 8px;
        }

        .widget-dnd {
          border-radius: 2px;
          background: ${colors.ui.bgAlt};
          padding: 4px 8px;
          margin: 4px;
        }

        .widget-dnd > switch {
          border-radius: 2px;
          background: ${colors.ui.bgElevated};
        }

        .widget-dnd > switch:checked {
          background: ${colors.accent.primary};
        }

        .widget-dnd > switch slider {
          border-radius: 2px;
        }

        .widget-buttons-grid > button {
          border-radius: 2px;
          background: ${colors.ui.bgAlt};
          border: none;
          color: ${colors.ui.fgDim};
        }

        .widget-buttons-grid > button:hover {
          background: ${colors.ui.bgElevated};
          color: ${colors.ui.fg};
        }

        .notification-action {
          border-radius: 2px;
          background: ${colors.ui.bgElevated};
          border: none;
          padding: 6px 10px;
          margin: 2px;
          color: ${colors.ui.fg};
        }

        .notification-action:hover {
          background: ${colors.accent.primary};
          color: ${bgSolid};
        }

        .close-button {
          border-radius: 2px;
          background: ${colors.ui.bgElevated};
          border: none;
          padding: 2px;
        }

        .close-button:hover {
          background: ${colors.accent.primary};
        }

        .summary { color: ${colors.ui.fg}; }
        .body { color: #9a958d; }
        .time { color: #5a554d; }
        .app-name { color: #5a554d; }
      '';
    };
  };
}
