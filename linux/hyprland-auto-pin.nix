# Home-manager module for Hyprland auto-pin services
# Auto-pins floating windows matching specific patterns (e.g., Picture-in-Picture)
{pkgs, ...}: let
  auto-pin-script = pkgs.writeShellApplication {
    name = "hyprland-auto-pin";
    runtimeInputs = [pkgs.hyprland pkgs.jq pkgs.socat pkgs.findutils];
    text = builtins.readFile ./scripts/hyprland-auto-pin.sh;
  };
in {
  systemd.user.services = {
    hyprland-auto-pin-pip = {
      Unit = {
        Description = "Auto-pin Picture-in-Picture windows";
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${auto-pin-script}/bin/hyprland-auto-pin \"title:Picture in picture\"";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
