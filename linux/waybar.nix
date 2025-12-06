{ config, lib, pkgs, ... }:

let
  # Control center as a proper derivation with GTK wrapping
  controlCenterGui = pkgs.stdenv.mkDerivation {
    pname = "waybar-control-center-gui";
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
      cp control-center.py $out/bin/waybar-control-center-gui
      chmod +x $out/bin/waybar-control-center-gui
    '';
    postFixup = ''
      wrapProgram $out/bin/waybar-control-center-gui \
        --prefix PATH : ${pkgs.lib.makeBinPath [ (pkgs.python3.withPackages (ps: with ps; [ pygobject3 pycairo ])) ]}
    '';
  };
in
{
  # Required packages
  environment.systemPackages = with pkgs; [
    brightnessctl
    controlCenterGui
  ];

  # Waybar configuration via home-manager
  home-manager.users.andrei = { config, pkgs, ... }: {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };

    # Config files from external sources
    xdg.configFile = {
      "waybar/config".source = ./waybar/config.json;
      "waybar/style.css".source = ./waybar/style.css;

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
      "waybar/scripts/control-center.sh" = {
        source = ./waybar/scripts/control-center.sh;
        executable = true;
      };
    };
  };
}
