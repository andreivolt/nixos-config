{ config, lib, pkgs, ... }:

{
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
          background: #0a0a0a;
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
          background: #1a1816;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.7);
        }

        .notification-content {
          border-radius: 2px;
          padding: 0;
          margin: 0;
        }

        .control-center .notification-row .notification-background {
          border-radius: 2px;
          background: #1a1816;
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
          background: #1a1816;
          border: none;
          padding: 4px 8px;
          color: #7a756d;
        }

        .notification-group-collapse-button,
        .notification-group-close-all-button {
          border-radius: 2px;
          background: #1a1816;
          border: none;
        }

        .image {
          border-radius: 2px;
        }

        .widget-title {
          border-radius: 0;
          background: transparent;
          color: #7a756d;
          padding: 4px 8px;
        }

        .widget-dnd {
          border-radius: 2px;
          background: #1a1816;
          padding: 4px 8px;
          margin: 4px;
        }

        .widget-dnd > switch {
          border-radius: 2px;
          background: #252220;
        }

        .widget-dnd > switch:checked {
          background: #b85555;
        }

        .widget-dnd > switch slider {
          border-radius: 2px;
        }

        .widget-buttons-grid > button {
          border-radius: 2px;
          background: #1a1816;
          border: none;
          color: #7a756d;
        }

        .widget-buttons-grid > button:hover {
          background: #252220;
          color: #d4d0ca;
        }

        .notification-action {
          border-radius: 2px;
          background: #252220;
          border: none;
          padding: 6px 10px;
          margin: 2px;
          color: #d4d0ca;
        }

        .notification-action:hover {
          background: #b85555;
          color: #0a0a0a;
        }

        .close-button {
          border-radius: 2px;
          background: #252220;
          border: none;
          padding: 2px;
        }

        .close-button:hover {
          background: #b85555;
        }

        .summary { color: #d4d0ca; }
        .body { color: #9a958d; }
        .time { color: #5a554d; }
        .app-name { color: #5a554d; }
      '';
    };
  };
}
