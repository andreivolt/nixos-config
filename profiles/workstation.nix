# Workstation/Desktop configuration for Linux
# Include this module for desktop/graphical environments
# For headless servers, use base.nix only
{
  pkgs,
  config,
  inputs,
  ...
}: {
  programs.gnupg.agent.pinentryPackage = pkgs.lib.mkForce pkgs.pinentry-all;
  # Workstation-specific packages (device-specific + GUI)
  environment.systemPackages =
    (import "${inputs.self}/packages/workstation.nix" pkgs)
    ++ (import "${inputs.self}/packages/gui.nix" pkgs);
  imports = [
    # Desktop hardware & peripherals
    ../linux/brother-printer.nix
    ../linux/brother-scanner.nix
    ../linux/networkmanager.nix

    # Services
    ../linux/mullvad.nix
    ../linux/tor.nix
    ../linux/socks-proxy.nix

    ../shared/ghostty
    ../shared/kitty
    ../shared/nvim-pager.nix
    ../shared/nushell
    ../shared/sublime
    ../shared/zed

    # GUI components
    ../shared/cursor.nix
    ../shared/fonts.nix
    ../linux/cliphist.nix
    ../linux/dropdown.nix
    ../linux/gnome-keyring.nix
    ../linux/greetd.nix
    ../linux/gtk.nix
    ../linux/hyprland
    ../linux/nm-applet.nix
    ../linux/pipewire.nix
    ../linux/bluetooth-audio.nix
    ../linux/qt.nix
    ../linux/swaybg.nix
    ../linux/swaync
    ../linux/trayscale.nix
    ../linux/vnc.nix
    ../linux/mpv.nix
    ../linux/waybar
    ../linux/xdg-portals.nix
    ../linux/chrome-history.nix
    ../linux/chromium.nix
    ../linux/dolphin.nix
    ../linux/kdeconnect.nix
    ../shared/chromium-extensions.nix
    ../shared/ff2mpv.nix
    ../linux/kbd-backlight-idle.nix
    ../linux/hyprsunset-wake.nix
    ../linux/wob.nix
    ../linux/screen-share.nix
  ];

  # GUI-specific hardware
  hardware.graphics.enable = true;

  # GUI-related services
  services.udisks2.enable = true;
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;

  home-manager.sharedModules = [
    {
      services.udiskie = {
        enable = true;
        notify = true;
        tray = "never";
      };
    }
  ];

  services.logind.settings.Login.HandlePowerKey = "suspend";

  networking.firewall.enable = true;

  boot.kernel.sysctl = {
    "vm.vfs_cache_pressure" = 50;  # keep more dentries/inodes cached
    "kernel.nmi_watchdog" = 0;     # disable for power savings
  };
}
