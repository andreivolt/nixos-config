# Power menu (suspend/reboot/shutdown)
{ pkgs, ... }:
{
  home-manager.sharedModules = [{
    home.packages = [
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
  }];
}
