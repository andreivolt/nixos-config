{ config, lib, pkgs, inputs, ... }:

let
  hyprlandPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system} // {
    hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [ ../../pkgs/hyprland-null-format-name.patch ];
    });
  };
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
  hyprsunsetPkg = inputs.hyprsunset.packages.${pkgs.stdenv.hostPlatform.system}.default;
  isAsahi = config.networking.hostName == "riva";

  # Patched hyprbars with blur, separator, text shadow, and top-only rounding
  hyprbarsPatched = hyprlandPlugins.hyprbars.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [ ./hyprbars.patch ];
  });

  # Blue light filter script (also includes P3 saturation boost for Asahi)
  bluelight = pkgs.writeShellScriptBin "bluelight" (builtins.readFile ./scripts/bluelight);
  # Screenshot wrapper - disables blue light filter during capture
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard imagemagick jq libnotify hyprpicker ];
    text = builtins.readFile ./scripts/screenshot;
  };
in {
  imports = [
    ./vars.nix
    ./cursor.nix
  ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
    package = hyprlandPkgs.hyprland;
    portalPackage = hyprlandPkgs.xdg-desktop-portal-hyprland;
  };

  services.hypridle.enable = true;

  programs.hyprlock.enable = true;

  environment.systemPackages = with pkgs; [
    hyprpicker
    hyprshot
    screenshot
  ] ++ (if isAsahi then [ bluelight ] else [ hyprsunsetPkg ])
    ++ (with hyprlandPkgs; [
    hyprland-qtutils
  ]);

  # Use home-manager's hyprland module to load plugins (ensures version match)
  # Config files are symlinked from nixos-config repo for live editing
  home-manager.sharedModules = [{
    systemd.user.targets.hyprland-session = {
      Unit = {
        Description = "Hyprland session";
        BindsTo = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  }];

  home-manager.users.andrei = { config, lib, ... }: {
    # Symlink config files from repo (out-of-store for live editing)
    home.file.".config/hypr/hyprlock.conf".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hyprlock.conf";
    home.file.".config/hypr/hypridle.conf".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hypridle.conf";
    home.file.".config/hypr/scripts".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/scripts";

    # Generate plugin load file (loaded synchronously, before windowrules)
    home.file.".config/hypr/plugins.conf".text = ''
      plugin = ${hyprbarsPatched}/lib/libhyprbars.so
    '';

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;  # Use system package
      portalPackage = null;
      systemd.enable = false;  # UWSM handles this
      plugins = [
        # Don't use home-manager plugins - it uses exec-once which loads too late
        # hyprbarsPatched
      ];
      extraConfig = ''
        # Load plugins first (synchronously) so windowrules work
        source = ~/.config/hypr/plugins.conf

        source = ${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hyprland.conf

        # Trayscale - float, pinned, centered, no titlebar
        windowrule = float on, match:class dev.deedles.Trayscale
        windowrule = pin on, match:class dev.deedles.Trayscale
        windowrule = size 400 500, match:class dev.deedles.Trayscale
        windowrule = center on, match:class dev.deedles.Trayscale
        windowrule = hyprbars:no_bar 1, match:class dev.deedles.Trayscale

      '';
    };

  };
}
