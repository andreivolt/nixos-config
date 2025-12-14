{ config, lib, pkgs, inputs, ... }:

let
  hyprlandPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hyprlandPlugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./vars.nix
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
    hyprshot
  ] ++ (with hyprlandPkgs; [
    hyprland-qtutils
  ]);

  # Use home-manager's hyprland module to load plugins (ensures version match)
  # Config files are symlinked from nixos-config repo for live editing
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

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;  # Use system package
      portalPackage = null;
      systemd.enable = false;  # UWSM handles this
      plugins = [
        hyprlandPlugins.hyprbars
        # hyprlandPlugins.hyprexpo  # TODO: causing version mismatch issues
      ];
      extraConfig = ''
        source = ${config.home.homeDirectory}/dev/nixos-config/linux/hyprland/hyprland.conf

        # Trayscale - float, pinned, centered, no titlebar
        windowrule = float on, match:class dev.deedles.Trayscale
        windowrule = pin on, match:class dev.deedles.Trayscale
        windowrule = size 400 500, match:class dev.deedles.Trayscale
        windowrule = center on, match:class dev.deedles.Trayscale
        windowrule = hyprbars:no_bar 1, match:class dev.deedles.Trayscale
      '';
    };

    # Reload hyprland only when config actually changes (not on every rebuild)
    # Works with misc.disable_autoreload = true in hyprland.conf
    home.activation.hyprlandReload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      HASH_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-config-hash"
      HYPR_DIR="$HOME/.config/hypr"
      REPO_CONF="$HOME/dev/nixos-config/linux/hyprland/hyprland.conf"

      # Hash all hyprland config files (follow symlinks to get actual content)
      # Include: wrapper, repo config, and all sourced configs
      if [ -d "$HYPR_DIR" ]; then
        NEW_HASH=$(cat "$HYPR_DIR/hyprland.conf" "$REPO_CONF" "$HYPR_DIR/vars.conf" "$HYPR_DIR/dropdown.conf" "$HYPR_DIR/cursor.conf" "$HYPR_DIR/touch.conf" 2>/dev/null | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)

        OLD_HASH=""
        [ -f "$HASH_FILE" ] && OLD_HASH=$(cat "$HASH_FILE")

        if [ "$NEW_HASH" != "$OLD_HASH" ]; then
          # Only reload if Hyprland is running
          if [ -d "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" ]; then
            echo "Hyprland config changed, reloading..."
            ${hyprlandPkgs.hyprland}/bin/hyprctl reload || true
          fi
          mkdir -p "$(dirname "$HASH_FILE")"
          echo "$NEW_HASH" > "$HASH_FILE"
        fi
      fi
    '';
  };
}
