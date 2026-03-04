# Mullvad+Tailscale DNS overrides
# Wraps NextDNS in mullvad-exclude so DNS survives VPN state changes
{ pkgs, config, lib, ... }: {
  systemd.services.nextdns = {
    after = [ "mullvad-daemon.service" ];
    serviceConfig.ExecStart = lib.mkForce (toString (pkgs.writeShellScript "nextdns-mullvad-excluded" ''
      exec ${pkgs.mullvad-vpn}/bin/mullvad-exclude \
        ${pkgs.nextdns}/bin/nextdns run \
          -config "$(cat ${config.sops.secrets."nextdns/setup_id".path})" \
          -listen 127.0.0.1:5354 \
          -report-client-info \
          -detect-captive-portals
    ''));
  };

  # NextDNS DoH connections go stale when Mullvad toggles (wg0-mullvad add/remove).
  # Restart via NM dispatcher.
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "restart-nextdns" ''
      if [ "$1" = "wg0-mullvad" ]; then
        systemctl restart nextdns
      fi
    '';
  }];
}
