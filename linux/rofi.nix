# Rofi launcher configuration
# Dark theme, green accents, Roboto, with icons
{ pkgs, ... }:
let
  colors = import ../shared/colors.nix;
in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "kitty";
    font = "Roboto 13";
    theme = "~/.config/rofi/theme.rasi";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      icon-theme = "Tela";
      display-drun = "";
      display-combi = "›";
      drun-display-format = "{name}";
      drun-show-actions = true;
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
      kb-remove-to-eol = "";
      kb-accept-entry = "Return,KP_Enter";
      kb-row-down = "Down,Control+j";
      kb-row-up = "Up,Control+k";
    };
  };

  xdg.configFile."rofi/theme.rasi".text = ''
    * {
      bg: ${colors.ui.bg};
      bg-sel: ${colors.ui.bgAlt};
      fg: ${colors.ui.fg};
      fg-alt: ${colors.ui.fgDim};
    }

    window {
      background-color: @bg;
      width: 33%;
      padding: 12px;
      border: 0;
      border-radius: 3px;
      location: north;
      anchor: north;
      y-offset: 50px;
    }

    mainbox {
      background-color: transparent;
      spacing: 10px;
      children: [ inputbar, listview ];
    }

    inputbar {
      background-color: transparent;
      padding: 10px 0;
      spacing: 10px;
      children: [ prompt, entry ];
    }

    prompt {
      background-color: transparent;
      text-color: @fg-alt;
    }

    entry {
      background-color: transparent;
      text-color: @fg;
      placeholder: "Search...";
      placeholder-color: @fg-alt;
    }

    listview {
      background-color: transparent;
      lines: 10;
      columns: 1;
      fixed-height: false;
      scrollbar: false;
      spacing: 4px;
    }

    element {
      background-color: transparent;
      text-color: @fg;
      padding: 5px 10px;
      spacing: 8px;
      border-radius: 3px;
    }

    element selected {
      background-color: @bg-sel;
      text-color: #ffffff;
    }

    element-icon {
      background-color: transparent;
      size: 20px;
    }

    element-text {
      background-color: transparent;
      text-color: inherit;
      vertical-align: 0.5;
    }
  '';

  home.packages = [
    # App launcher with combi mode (windows + apps)
    # Shows running windows first, then apps - selecting a window focuses it
    (pkgs.writeShellScriptBin "rofi-launch" ''
      rofi -show combi -combi-modi "window,drun" -modi combi
    '')

    # Clipboard history
    (pkgs.writeShellScriptBin "rofi-clip" ''
      cliphist list | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Clipboard" | cliphist decode | wl-copy
    '')

    # Power menu
    (pkgs.writeShellScriptBin "rofi-power" ''
      options="Lock\nLogout\nSuspend\nReboot\nShutdown"
      selected=$(echo -e "$options" | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Power")

      case "$selected" in
        Lock) hyprlock ;;
        Logout)
          confirm=$(echo -e "Yes\nNo" | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Logout?")
          [ "$confirm" = "Yes" ] && hyprctl dispatch exit
          ;;
        Suspend) systemctl suspend ;;
        Reboot)
          confirm=$(echo -e "Yes\nNo" | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Reboot?")
          [ "$confirm" = "Yes" ] && systemctl reboot
          ;;
        Shutdown)
          confirm=$(echo -e "Yes\nNo" | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Shutdown?")
          [ "$confirm" = "Yes" ] && systemctl poweroff
          ;;
      esac
    '')
  ];
}
