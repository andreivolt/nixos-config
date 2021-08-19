{ config, pkgs, ... }:

let
  timeouts = {
    lock = "1800";
    display = "180";
    suspend = "7200";
  };
in {
  home-manager.users.avo.systemd.user.services.swayidle = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service.ExecStart = ''
      ${pkgs.swayidle}/bin/swayidle -w \
        timeout ${timeouts.lock} '${pkgs.swaylock}/bin/swaylock -f -c 000000' \
        timeout ${timeouts.display} '${pkgs.sway}/bin/swaymsg "output * dpms off"' \
          resume '${pkgs.sway}/bin/swaymsg "output * dpms on"' \
        timeout ${timeouts.suspend} 'systemctl suspend'
    '';

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
