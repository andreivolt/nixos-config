{ pkgs, ... }:

{
  xdg.portal.enable = true;

  xdg.portal.wlr.enable = true;

  xdg.portal.gtkUsePortal = true;

  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
  ];
}
