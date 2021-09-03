{ config, ... }:

{
  users.users.avo.extraGroups = [ "input" ];

  home-manager.users.avo = { pkgs, ... }: {
    systemd.user.services.gebaard = {
      Unit = {
        After = [ "sway-session-pre.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Install.WantedBy = [ "sway-session.target" ];
      Service.ExecStart = "${pkgs.gebaar-libinput}/bin/gebaard";
      # restartTriggers = [
      #   config.home-manager.users.avo.xdg.configFile."gebaar/gebaard.toml".source
      # ];
    };

    xdg.configFile."gebaar/gebaard.toml".text = ''
      [commands.swipe.three]
      # left_up = "notify-send three_left_up"
      # right_up = "notify-send three_right_up"
      # up = "notify-send three_up"
      # left_down = "notify-send three_left_down"
      # right_down = "notify-send three_right_down"
      # down = "notify-send three_down"
      left = "swaymsg workspace next_on_output"
      right = "swaymsg workspace prev_on_output"

      [commands.swipe.four]
      # left_up = "notify-send four_left_up"
      # right_up = "notify-send four_right_up"
      # up = "notify-send four_up"
      # left_down = "notify-send four_left_down"
      # right_down = "notify-send four_right_down"
      # down = "notify-send four_down"
      # left = "notify-send four_left"
      # right = "notify-send four_right"
    '';
  };
}
