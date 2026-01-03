# Hyprland cursor environment variables
# Sourced via hyprland.conf: source = ~/.config/hypr/cursor.conf
{pkgs, ...}: let
  cursor-theme = "Adwaita";
  cursor-size = 24;
in {
  home-manager.users.andrei.xdg.configFile."hypr/cursor.conf".text = ''
    env = XCURSOR_THEME,${cursor-theme}
    env = XCURSOR_SIZE,${toString cursor-size}
    env = HYPRCURSOR_THEME,${cursor-theme}
    env = HYPRCURSOR_SIZE,${toString cursor-size}
  '';
}
