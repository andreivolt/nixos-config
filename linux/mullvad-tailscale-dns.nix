# DNS that survives Mullvad+Tailscale VPN state changes
# NextDNS DoH excluded from Mullvad tunnel, dnsmasq as local resolver
{ pkgs, config, lib, ... }: let
  nextdnsStart = pkgs.writeShellScript "nextdns-mullvad-excluded" ''
    exec ${pkgs.mullvad-vpn}/bin/mullvad-exclude \
      ${pkgs.nextdns}/bin/nextdns run \
        -config "$(cat ${config.sops.secrets."nextdns/setup_id".path})" \
        -listen 127.0.0.1:5354 \
        -report-client-info \
        -detect-captive-portals
  '';
in {
  services.nextdns.enable = true;
  systemd.services.nextdns = {
    after = [ "mullvad-daemon.service" ];
    serviceConfig.ExecStart = lib.mkForce "${nextdnsStart}";
  };

  # NextDNS DoH connections go stale when Mullvad toggles (wg0-mullvad add/remove).
  # It detects the network change but never recovers. Restart via NM dispatcher.
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "restart-nextdns" ''
      if [ "$1" = "wg0-mullvad" ]; then
        systemctl restart nextdns
      fi
    '';
  }];

  # Standalone dnsmasq (NM's internal dnsmasq ignores dnsmasq.d/ conf files)
  networking.networkmanager.dns = "none";
  services.dnsmasq = {
    enable = true;
    settings = {
      no-resolv = true;
      listen-address = "127.0.0.1";
      bind-interfaces = true;
      server = [
        "127.0.0.1#5354"
        "/tail.avolt.net/100.100.100.100"
        "/pw.avolt.net/100.100.100.100"
      ];
      address = "/mafreebox.freebox.fr/192.168.1.254";
    };
  };
}
