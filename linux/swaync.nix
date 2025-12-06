{ config, lib, pkgs, ... }:

{
  # Install swaync package
  environment.systemPackages = [ pkgs.swaynotificationcenter ];

  # SwayNotificationCenter service
  home-manager.users.andrei = { config, pkgs, ... }: {
    services.swaync = {
      enable = true;
      settings = {
        cssPriority = "user";
      };
      style = ''
        * {
          font-family: Roboto, sans-serif;
          border-radius: 3px;
        }

        .control-center {
          border-radius: 0;
          background: #000000;
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
          border-radius: 3px;
          padding: 0;
        }

        .notification-background {
          border-radius: 3px;
          border: none;
          padding: 10px;
          background: #1a1a1a;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.8);
        }

        .notification-content {
          border-radius: 3px;
          padding: 0;
          margin: 0;
        }

        .control-center .notification-row .notification-background {
          border-radius: 3px;
          background: #1a1a1a;
          border: none;
        }

        .notification-group {
          border-radius: 3px;
        }

        .notification-group-headers {
          border-radius: 3px;
          background: transparent;
        }

        .notification-group-headers > button {
          border-radius: 3px;
          background: #1a1a1a;
          border: none;
          padding: 4px 8px;
          color: #888888;
        }

        .notification-group-collapse-button,
        .notification-group-close-all-button {
          border-radius: 3px;
          background: #1a1a1a;
          border: none;
        }

        .image {
          border-radius: 3px;
        }

        .widget-title {
          border-radius: 0;
          background: transparent;
          color: #888888;
          padding: 4px 8px;
        }

        .widget-dnd {
          border-radius: 3px;
          background: #1a1a1a;
          padding: 4px 8px;
          margin: 4px;
        }

        .widget-dnd > switch {
          border-radius: 3px;
          background: #333333;
        }

        .widget-dnd > switch:checked {
          background: #444444;
        }

        .widget-dnd > switch slider {
          border-radius: 3px;
        }

        .widget-buttons-grid > button {
          border-radius: 3px;
          background: #1a1a1a;
          border: none;
        }

        .notification-action {
          border-radius: 3px;
          background: #333333;
          border: none;
          padding: 4px 8px;
          margin: 2px;
        }

        .close-button {
          border-radius: 3px;
          background: #333333;
          border: none;
          padding: 2px;
        }

        .summary { color: #cccccc; }
        .body { color: #999999; }
        .time { color: #666666; }
        .app-name { color: #666666; }
      '';
    };
  };
}
