{ pkgs, ... }:

{
  launchd.daemons.nginx = with pkgs; {
    command = "${nginx}/bin/nginx";
    path = [ nginx ];
  };
}
