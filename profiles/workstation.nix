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
    ../linux/v4l2loopback.nix

    # Services
    ../linux/tor.nix

    ../shared/alacritty.nix
    ../shared/ghostty.nix
    ../shared/kitty.nix
    ../linux/swayimg.nix

    # GUI components
    ../shared/cursor.nix
    ../shared/fonts.nix
    ../linux/cliphist.nix
    ../linux/dropdown.nix
    # ../linux/eww.nix
    ../linux/gnome-keyring.nix
    ../linux/greetd.nix
    ../linux/gtk.nix
    ../linux/hyprland
    ../linux/nm-applet.nix
    ../linux/pipewire.nix
    ../linux/qt.nix
    ../linux/swaybg.nix
    ../linux/swaync.nix
    ../linux/trayscale.nix
    ../linux/wayvnc.nix
    ../linux/mpv.nix
    ../linux/waybar.nix
    ../linux/xdg-portals.nix
    ../linux/chromium.nix
    ../linux/dolphin.nix
    ../linux/kdeconnect.nix
    ../shared/ff2mpv.nix
    ../linux/kbd-backlight-idle.nix
  ];

  # GUI-specific hardware
  hardware.graphics.enable = true;

  # GUI-related services
  services.udisks2.enable = true;
  services.flatpak.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;

  # Battery monitoring for laptops
  home-manager.sharedModules = [
    {
      services.batsignal = {
        enable = true;
        extraArgs = [
          "-w" "40"
          "-c" "20"
          "-d" "10"
        ];
      };
      services.udiskie = {
        enable = true;
        notify = true;
        tray = "never";
      };
    }
  ];

  services.logind.settings.Login.HandlePowerKey = "suspend";

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };
}
