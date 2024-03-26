{ lib, ... }:

let
  hostsfiles = [
    https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
    https://winhelp2002.mvps.org/hosts.txt
    https://someonewhocares.org/hosts/
  ];
in
{
  networking.extraHosts =
    lib.concatStrings
      (map builtins.readFile
        (map builtins.fetchurl hostsfiles));
}
