{pkgs, ...}: {
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # Note: xdg-desktop-portal-hyprland is automatically added by programs.hyprland
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    # Configure which portal handles which interface
    config = {
      common = {
        default = [ "gnome" "gtk" ];
      };
      hyprland = {
        default = [ "gnome" "hyprland" "gtk" ];
        # Hyprland portal handles these specific interfaces
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
        # GNOME portal for Settings (better dark mode support)
        "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
      };
    };
  };
}
