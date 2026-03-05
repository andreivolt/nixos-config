# NextDNS DoH resolver with dnsmasq as local frontend
{ pkgs, config, ... }: {
  services.nextdns.enable = true;
  systemd.services.nextdns.serviceConfig.ExecStart = pkgs.lib.mkDefault (toString (pkgs.writeShellScript "nextdns-start" ''
    exec ${pkgs.nextdns}/bin/nextdns run \
      -config "$(cat ${config.sops.secrets."nextdns/setup_id".path})" \
      -listen 127.0.0.1:5354 \
      -report-client-info \
      -detect-captive-portals
  ''));

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
      ];
    };
  };
}
