# Tailscale with Headscale, exit node, and UDP GRO forwarding
{ pkgs, ... }: {
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--operator=andrei" "--login-server=https://hs.avolt.net" "--advertise-exit-node"];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  # UDP GRO forwarding for better exit node throughput
  # https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
  systemd.services.tailscale-gro = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "tailscale-gro" ''
        dev=$(${pkgs.iproute2}/bin/ip -o route get 1.1.1.1 | ${pkgs.gawk}/bin/awk '{print $5}')
        ${pkgs.ethtool}/bin/ethtool -K "$dev" rx-udp-gro-forwarding on rx-gro-list off 2>/dev/null || true
      '';
    };
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];

  # Route tailnet Magic DNS (*.tail.avolt.net) through Tailscale's resolver
  services.dnsmasq.settings.server = [
    "/tail.avolt.net/100.100.100.100"  # Magic DNS for tailnet hostnames
    "/pw.avolt.net/100.100.100.100"    # Vaultwarden (tailnet-only)
  ];
}
