# Mullvad VPN with Tailscale coexistence
# After rebuild: mullvad account login <account-number>
# SOCKS5 proxy available at 10.64.0.1:1080 when connected
{pkgs, config, lib, ...}: let
  nextdnsStart = pkgs.writeShellScript "nextdns-mullvad-excluded" ''
    exec ${pkgs.mullvad-vpn}/bin/mullvad-exclude \
      ${pkgs.nextdns}/bin/nextdns run \
        -config "$(cat ${config.sops.secrets."nextdns/setup_id".path})" \
        -listen 127.0.0.1:5354 \
        -report-client-info \
        -detect-captive-portals
  '';
in {
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # Declaratively configure Mullvad settings after daemon starts
  systemd.services.mullvad-daemon.postStart = ''
    while ! ${pkgs.mullvad}/bin/mullvad status &>/dev/null; do sleep 1; done
    ${pkgs.mullvad}/bin/mullvad lan set allow
    ${pkgs.mullvad}/bin/mullvad connect
  '';

  # Route Tailscale CGNAT traffic through Tailscale's table before Mullvad's VPN table.
  # Without this, Mullvad's routing table (rule 5209) catches 100.64.0.0/10 and routes
  # it through wg0-mullvad. The ct mark + type route rerouting approach doesn't work
  # because conntrack SNAT bindings from previous routing decisions prevent rerouting.
  networking.localCommands = ''
    ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
  '';

  # Mullvad recreates its nftables rules on every connect, wiping custom rules from
  # its inet mullvad table. Re-insert tailscale0 accept rules on each state change.
  # Needed for: input (incoming Tailscale traffic), output (outgoing to Tailscale),
  # and forward (exit node traffic through Mullvad tunnel).
  systemd.services.mullvad-tailscale-rules = {
    description = "Re-insert Tailscale rules in Mullvad nftables on state changes";
    after = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "mullvad-tailscale-rules" ''
        nft=${pkgs.nftables}/bin/nft
        insert_if_missing() {
          local chain=$1 match=$2 rule=$3
          if $nft list chain inet mullvad "$chain" &>/dev/null; then
            if ! $nft list chain inet mullvad "$chain" | grep -q "$match"; then
              $nft insert rule inet mullvad "$chain" $rule
            fi
          fi
        }
        ${pkgs.mullvad}/bin/mullvad status listen | while read -r line; do
          insert_if_missing input tailscale0 'iifname "tailscale0" accept'
          insert_if_missing output tailscale0 'oif "tailscale0" accept'
          insert_if_missing forward tailscale0 'iifname "tailscale0" oifname "wg0-mullvad" accept'
        done
      '';
      Restart = "always";
      RestartSec = 5;
    };
  };

  # zsh completions (mullvad-vpn doesn't propagate them from the mullvad CLI package)
  environment.systemPackages = [
    (pkgs.runCommandLocal "mullvad-zsh-completions" {} ''
      mkdir -p $out/share/zsh/site-functions
      cp ${pkgs.mullvad}/share/zsh/site-functions/_mullvad $out/share/zsh/site-functions/
    '')
  ];

  # Tailscale + Mullvad coexistence nftables rules
  # The routing rule (localCommands above) handles routing Tailscale traffic correctly.
  # The mullvad-tailscale-rules service handles Mullvad's firewall accept rules.
  # This table handles exit node forwarding (MSS clamping, QUIC blocking, MASQUERADE).
  networking.nftables.enable = true;
  networking.nftables.tables.mullvad-tailscale = {
    family = "inet";
    content = ''
      chain forward {
        type filter hook forward priority mangle; policy accept;
        # Clamp TCP MSS for double WireGuard encapsulation (tailscale MTU 1280)
        iifname "tailscale0" oifname "wg0-mullvad" tcp flags syn tcp option maxseg size set 1228;
        iifname "wg0-mullvad" oifname "tailscale0" tcp flags syn tcp option maxseg size set 1228;
        # Block QUIC (UDP 443) to force TCP fallback — avoids PMTU black hole on return path
        iifname "tailscale0" oifname "wg0-mullvad" udp dport 443 drop;
      }
      # MASQUERADE forwarded exit node traffic so Mullvad server accepts it
      # (Mullvad only accepts traffic sourced from the assigned VPN IP)
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "wg0-mullvad" ip saddr 100.64.0.0/10 masquerade;
      }
    '';
  };

  # Required for Tailscale to work properly with Mullvad
  networking.firewall.checkReversePath = "loose";

  # Local SOCKS5 proxy that bypasses Mullvad tunnel
  systemd.services.mullvad-exclude-proxy = {
    description = "SOCKS5 proxy excluded from Mullvad VPN";
    after = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad-exclude ${pkgs.microsocks}/bin/microsocks -i 127.0.0.1 -p 1090";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # HTTP proxy bypassing Mullvad (for mpv which only supports HTTP proxies)
  systemd.services.mullvad-exclude-http-proxy = {
    description = "HTTP proxy excluded from Mullvad VPN";
    after = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad-exclude ${pkgs.tinyproxy}/bin/tinyproxy -d -c ${pkgs.writeText "tinyproxy.conf" ''
        Port 1091
        Listen 127.0.0.1
        MaxClients 50
        DisableViaHeader Yes
      ''}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # Local DoH resolver bypassing Mullvad (so DNS survives VPN state changes)
  # Tailscale's DoH to NextDNS breaks when Mullvad toggles because the HTTPS
  # connections get torn down. This runs NextDNS DoH directly, excluded from Mullvad.
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
      ];
      address = "/mafreebox.freebox.fr/192.168.1.254";
    };
  };

  # Persist VPN credentials and device key across reboots
  environment.persistence."/persist".directories = [
    "/etc/mullvad-vpn"
  ];
}
