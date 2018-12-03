{
  networking.firewall = {
    allowedTCPPorts = [ 1988 8008 8009 5556 5558 ];
    allowedUDPPortRanges = [ { from = 32768; to = 60000; } ];
  };
}
