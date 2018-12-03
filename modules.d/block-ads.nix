{
  networking.extraHosts = builtins.readFile (builtins.fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts);
}
