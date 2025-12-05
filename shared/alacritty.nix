{
  home-manager.sharedModules = [
    {
      programs.alacritty = {
        enable = true;

        settings = {
          window = {
            opacity = 0.65;
            blur = true;
            padding = {
              x = 0;
              y = 0;
            };
            decorations = "None";
            startup_mode = "SimpleFullscreen";
          };

          font = {
            normal = {
              family = "IosevkaTerm Nerd Font Mono";
              style = "Light";
            };
            italic = {
              family = "IosevkaTerm Nerd Font Mono";
              style = "Light Italic";
            };
            size = 18;
            offset = {
              x = -3;
              y = -4;
            };
          };

          # Aurora theme
          colors = {
            primary = {
              foreground = "#ffffff";
              background = "#000000";
            };
            cursor = {
              text = "#211c2f";
              cursor = "#ddd0f4";
            };
            vi_mode_cursor = {
              text = "#211c2f";
              cursor = "#ddd0f4";
            };
            selection = {
              text = "#e7d3fb";
              background = "#3f4060";
            };
            normal = {
              black = "#070510";
              red = "#ff5874";
              green = "#addb67";
              yellow = "#ffcb65";
              blue = "#be9af7";
              magenta = "#FD9720";
              cyan = "#A1EFE4";
              white = "#645775";
            };
            bright = {
              black = "#443d60";
              red = "#ec5f67";
              green = "#d7ffaf";
              yellow = "#fbec9f";
              blue = "#6690c4";
              magenta = "#ffbe00";
              cyan = "#54CED6";
              white = "#e7d3fb";
            };
          };

          cursor = {
            style = {
              shape = "Beam";
              blinking = "On";
            };
            blink_timeout = 0;
          };

          mouse = {
            hide_when_typing = true;
          };

          keyboard = {
            bindings = [
              {
                key = "Return";
                mods = "Shift";
                chars = "\n";
              }
              {
                key = "Left";
                mods = "Command";
                chars = "\\x1b[1;5D";
              }
              {
                key = "Right";
                mods = "Command";
                chars = "\\x1b[1;5C";
              }
              {
                key = "Equals";
                mods = "Command";
                action = "IncreaseFontSize";
              }
              {
                key = "Plus";
                mods = "Command";
                action = "IncreaseFontSize";
              }
              {
                key = "Minus";
                mods = "Command";
                action = "DecreaseFontSize";
              }
            ];
          };

          bell = {
            duration = 0;
          };
        };
      };
    }
  ];
}
