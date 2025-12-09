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

    # Auto-restart waybar when CSS changes
    # moved_to: atomic rename (Claude Edit tool, some editors)
    # close_write: direct write (vim, manual edits)
    systemd.user.services.waybar-css-watcher = {
      Unit = {
        Description = "Watch waybar CSS for changes";
        After = [ "waybar.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "waybar-css-watcher" ''
          ${pkgs.inotify-tools}/bin/inotifywait -m -e moved_to,close_write "$HOME/dev/nixos-config/linux/waybar/" |
          while read -r dir event file; do
            if [ "$file" = "style.css" ]; then
              ${pkgs.systemd}/bin/systemctl --user restart waybar
            fi
          done
        ''}";
        Restart = "always";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Config files from external sources
    xdg.configFile = {
      "waybar/config".source = ./waybar/config.json;
      # Out-of-store symlink for live CSS editing without rebuild
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
