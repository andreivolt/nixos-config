{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ libnotify ];

  systemd.user.services.notify-osd = {
    wantedBy = [ "graphical-session.target" ]; after = [ "graphical-session-pre.target" ]; partOf = [ "graphical-session.target" ];
    path = with pkgs; [ notify-osd ];
    script = "notify-osd";
  };
}
