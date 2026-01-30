{ ... }:

{
  # catt serves local files on a random port in 45000-47000
  networking.firewall.allowedTCPPortRanges = [{ from = 45000; to = 47000; }];
}
