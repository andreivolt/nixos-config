{ pkgs, lib, inputs }:
let
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
in {
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  # /run/current-system: cursor themes, system binaries (hyprctl etc.)
  # Apple Silicon GPU: platform devices (nixpak's gpu module only binds PCI paths)
  commonRoBinds = [
    "/run/current-system"
  ] ++ lib.optionals isAarch64 [
    "/sys/devices/platform"
    "/sys/class/drm"
  ];

  # Fonts, dark mode, locale — sloth-dependent
  guiRoBinds = sloth: [
    "/etc/fonts"
    "/etc/localtime"
    (sloth.concat' sloth.homeDir "/.config/gtk-3.0")
    (sloth.concat' sloth.homeDir "/.config/gtk-4.0")
    (sloth.concat' sloth.homeDir "/.config/dconf")
  ];

  commonDbusPolices = {
    "org.freedesktop.Notifications" = "talk";
    "org.freedesktop.portal.Desktop" = "talk";
    "org.freedesktop.portal.Settings" = "talk";
  };
}
