{ pkgs, ... }:

let
  lifx = pkgs.callPackage ./default.nix { };
in
{
  environment.systemPackages = [ lifx ];

  # LIFX uses UDP broadcast for discovery. Responses come FROM port 56700
  # and won't match conntrack state (broadcast doesn't create proper entries),
  # so we need to explicitly allow packets with source port 56700.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -p udp --sport 56700 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p udp --sport 56700 -j nixos-fw-accept || true
  '';
}
