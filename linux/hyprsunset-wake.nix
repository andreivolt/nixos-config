{ config, lib, pkgs, ... }:

let
  user = "andrei";
  minSleepHours = 4;
in
{
  home-manager.users.${user} = { config, pkgs, ... }: {
    systemd.user.services.hyprsunset-wake = {
      Unit = {
        Description = "Reset hyprsunset on wake (morning only, after 4h sleep)";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "hyprsunset-wake" ''
          sleep_file=/run/hyprsunset-sleep-time
          min_sleep=${toString (minSleepHours * 3600)}

          # check sleep duration
          if [ -f "$sleep_file" ]; then
            sleep_time=$(cat "$sleep_file")
            now=$(date +%s)
            slept=$((now - sleep_time))
            rm -f "$sleep_file"

            [ "$slept" -lt "$min_sleep" ] && exit 0
          fi

          # check if morning
          hour=$(date +%H)
          if [ "$hour" -ge 5 ] && [ "$hour" -lt 12 ]; then
            ${pkgs.procps}/bin/pkill hyprsunset || true
            ${pkgs.hyprsunset}/bin/hyprsunset -i
          fi
        '';
      };
    };
  };

  # record sleep time before suspend
  systemd.services.hyprsunset-sleep-record = {
    description = "Record sleep timestamp for hyprsunset";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'date +%s > /run/hyprsunset-sleep-time'";
    };
  };

  # trigger user service on wake
  systemd.services.hyprsunset-wake-trigger = {
    description = "Trigger hyprsunset-wake user service on wake";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = "${pkgs.systemd}/bin/systemctl --user -M ${user}@ start hyprsunset-wake.service";
    };
  };
}
