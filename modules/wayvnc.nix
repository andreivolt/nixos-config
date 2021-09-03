{ config, pkgs, ... }:

{
  systemd.services."netns@" = {
    description = "%I network namespace";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      PrivateNetwork = true;
      ExecStart = (pkgs.writeScript "netns-up" ''
        #! ${pkgs.bash}/bin/bash
        ${pkgs.iproute}/bin/ip netns add $1
        ${pkgs.utillinux}/bin/umount /var/run/netns/$1
        ${pkgs.utillinux}/bin/mount --bind /proc/self/ns/net /var/run/netns/$1
      '') + " %I";
      ExecStop = "${pkgs.iproute}/bin/ip netns del %I";
    };
  };

  home-manager.users.avo = { pkgs, ... }: {
    home.packages = with pkgs; [ wayvnc ];

    systemd.user.services.wayvnc = {
      Unit = {
        PartOf = [ "sway-session.target" ];
        After = [ "netns@tailscale0.service" "sway-session.target" ];
        BindsTo = [ "netns@tailscale0.service" ];
        ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
        JoinsNameSpaceOf = "netns@tailscale0.service";
      };
      # bindsTo = [ "netns@wg.service" ];
      # after = [ "netns@wg.service" ];
      # unitConfig.JoinsNamespaceOf = "netns@wg.service";
      # serviceConfig.PrivateNetwork = true;
      Service.PrivateNetwork = true;
      Service.ExecStart = "${pkgs.wayvnc}/bin/wayvnc";
      Install.WantedBy = [ "sway-session.target" ];
    };
  };
}
