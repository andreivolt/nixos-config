let
  stevenblack_hosts = builtins.fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
in {
  networking.extraHosts = builtins.readFile stevenblack_hosts;
}
