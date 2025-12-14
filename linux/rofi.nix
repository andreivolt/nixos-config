# Rofi launcher configuration
# Obsidian Aurora theme - warm copper accents
{ pkgs, ... }:
let
  colors = import ../shared/colors.nix;
in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "kitty --single-instance";
    font = "Roboto 13";
    theme = "~/.config/rofi/theme.rasi";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      icon-theme = "Papirus-Dark";
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
      bg-alt: ${colors.ui.bgAlt};
      bg-sel: ${colors.ui.bgElevated};
      fg: ${colors.ui.fg};
      fg-dim: ${colors.ui.fgDim};
      fg-muted: ${colors.ui.fgMuted};
      accent: ${colors.accent.primary};
      accent-dim: ${colors.accent.dim};
    }

    window {
      background-color: @bg;
      width: 33%;
      padding: 16px;
      border: 1px;
      border-color: @bg-alt;
      border-radius: 2px;
      location: north;
      anchor: north;
      y-offset: 50px;
    }

    mainbox {
      background-color: transparent;
      spacing: 12px;
      children: [ inputbar, listview ];
    }

    inputbar {
      background-color: @bg-alt;
      padding: 12px 14px;
      spacing: 10px;
      border-radius: 2px;
      children: [ prompt, entry ];
    }

    prompt {
      background-color: transparent;
      text-color: @accent;
    }

    entry {
      background-color: transparent;
      text-color: @fg;
      placeholder: "Search...";
      placeholder-color: @fg-muted;
    }

    listview {
      background-color: transparent;
      lines: 10;
      columns: 1;
      fixed-height: false;
      scrollbar: false;
      spacing: 2px;
    }

    element {
      background-color: transparent;
      text-color: @fg-dim;
      padding: 8px 12px;
      spacing: 10px;
      border-radius: 2px;
    }

    element selected {
      background-color: @bg-sel;
      text-color: @fg;
    }

    element-icon {
      background-color: transparent;
      size: 22px;
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
