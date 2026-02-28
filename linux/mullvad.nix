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
  # Without this, Mullvad's routing table catches 100.64.0.0/10 and routes it through
  # wg0-mullvad. Priority 5100 to come before Mullvad's rules (5198-5209 depending on host).
  networking.localCommands = ''
    ip rule add to 100.64.0.0/10 lookup 52 priority 5100 2>/dev/null || true
  '';

  # zsh completions (mullvad-vpn doesn't propagate them from the mullvad CLI package)
  environment.systemPackages = [
    (pkgs.runCommandLocal "mullvad-zsh-completions" {} ''
      mkdir -p $out/share/zsh/site-functions
      cp ${pkgs.mullvad}/share/zsh/site-functions/_mullvad $out/share/zsh/site-functions/
    '')
  ];

  # Tailscale + Mullvad coexistence nftables rules.
  # ct mark rules run at priority -100 (before Mullvad's chains at priority 0).
  # They set Mullvad's exclusion marks on Tailscale CGNAT traffic so Mullvad's own
  # "ct mark 0x00000f41 accept" rules pass it through. Static table, no timing issues.
  networking.nftables.enable = true;
  networking.nftables.tables.mullvad-tailscale = {
    family = "inet";
    content = ''
      chain output {
        type route hook output priority -100; policy accept;
        ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
      }
      chain input {
        type filter hook input priority -100; policy accept;
        ip saddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
      }
      chain prerouting {
        type filter hook prerouting priority -50; policy accept;
        iifname "wg0-mullvad" ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
      }
      chain forward {
        type filter hook forward priority mangle; policy accept;
        # Clamp TCP MSS for double WireGuard encapsulation (tailscale MTU 1280)
        iifname "tailscale0" oifname "wg0-mullvad" tcp flags syn tcp option maxseg size set 1228;
        iifname "wg0-mullvad" oifname "tailscale0" tcp flags syn tcp option maxseg size set 1228;
        # Block QUIC (UDP 443) to force TCP fallback — avoids PMTU black hole on return path
        iifname "tailscale0" oifname "wg0-mullvad" udp dport 443 drop;
      }
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
        "/pw.avolt.net/100.100.100.100"
      ];
      address = "/mafreebox.freebox.fr/192.168.1.254";
    };
  };

  # Persist VPN credentials and device key across reboots
  environment.persistence."/persist".directories = [
    "/etc/mullvad-vpn"
  ];
}
