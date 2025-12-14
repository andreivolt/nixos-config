{ config, lib, pkgs, ... }:

let
  # Waybar popups as a proper derivation with GTK wrapping
  waybarPopups = pkgs.stdenv.mkDerivation {
    pname = "waybar-popups";
    version = "1.0";
    src = ./waybar;
    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection ];
    buildInputs = [
      pkgs.gtk3
      pkgs.gtk-layer-shell
      (pkgs.python3.withPackages (ps: with ps; [ pygobject3 pycairo ]))
    ];
    installPhase = ''
      mkdir -p $out/bin
      cp slider-popup.py $out/bin/waybar-slider-popup
      chmod +x $out/bin/waybar-slider-popup
    '';
    postFixup = ''
      wrapProgram $out/bin/waybar-slider-popup \
        --prefix PATH : ${pkgs.lib.makeBinPath [ (pkgs.python3.withPackages (ps: with ps; [ pygobject3 pycairo ])) ]}
    '';
  };
in
{
  # Required packages
  environment.systemPackages = with pkgs; [
    brightnessctl
    waybarPopups
  ];

  # Waybar configuration via home-manager
  home-manager.users.andrei = { config, pkgs, ... }: {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };

    # Auto-restart waybar when config files change
    systemd.user.paths.waybar-config-watcher = {
      Unit.Description = "Watch waybar config for changes";
      Path.PathChanged = [
        "/home/andrei/dev/nixos-config/linux/waybar/style.css"
        "/home/andrei/dev/nixos-config/linux/waybar/config.json"
      ];
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.services.waybar-config-watcher = {
      Unit.Description = "Reload waybar on config change";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.procps}/bin/pkill -SIGUSR2 waybar";
      };
    };

    # Config files from external sources
    xdg.configFile = {
      # Out-of-store symlinks for live editing without rebuild
      "waybar/config".source = config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/waybar/config.json";
      "waybar/style.css" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/andrei/dev/nixos-config/linux/waybar/style.css";
        onChange = "${pkgs.systemd}/bin/systemctl --user restart waybar || true";
      };

      "waybar/scripts/get-brightness.sh" = {
        source = ./waybar/scripts/get-brightness.sh;
        executable = true;
      };
      "waybar/scripts/get-kbd-backlight.sh" = {
        source = ./waybar/scripts/get-kbd-backlight.sh;
        executable = true;
      };
      "waybar/scripts/tailscale-status.sh" = {
        source = ./waybar/scripts/tailscale-status.sh;
        executable = true;
      };
      "waybar/scripts/dictate-status.sh" = {
        source = ./waybar/scripts/dictate-status.sh;
        executable = true;
      };
      "waybar/scripts/kbd-backlight-toggle.sh" = {
        source = ./waybar/scripts/kbd-backlight-toggle.sh;
        executable = true;
      };
      "waybar/scripts/caffeine.sh" = {
        source = ./waybar/scripts/caffeine.sh;
        executable = true;
      };
    };
  };
}
