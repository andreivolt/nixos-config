{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ redshift ];

  systemd.user.services.reset-redshift = {
    enable = true;
    after = [ "suspend.target "];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${pkgs.avo-scripts}/bin/nightlight -x";
    };
  };
}
