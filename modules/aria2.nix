{ pkgs, ... }:

let
  extraAria2Args = [
    "--seed-time=0"
    "--dir=/tmp/aria2-temp"
    "--on-download-complete=${pkgs.writeShellScriptBin "aria2-download-complete" ''
      mv "$3" /home/avo/Downloads
      ${pkgs.libnotify}/bin/notify-send "Download Complete" "\$3 moved to /home/avo/Downloads"
      exit 0
    ''}/bin/aria2-download-complete"
  ];
in
{
  services.aria2 = {
    enable = true;
    extraArguments = builtins.concatStringsSep " " extraAria2Args;
  };

  environment.systemPackages = with pkgs; [ libnotify ];
}
