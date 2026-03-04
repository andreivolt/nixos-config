# Mullvad VPN with Tailscale coexistence
# After rebuild: mullvad account login <account-number>
{ pkgs, ... }: {
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
  # Without this, the initial routing for Tailscale IPs goes through Mullvad's table
  # (wg0-mullvad), giving responses the wrong source IP (Mullvad VPN IP instead of
  # Tailscale IP). This causes conntrack NAT tuple collisions that silently drop packets.
  # Mullvad dynamically positions its ip rules just before any existing rules, so a
  # static priority gets leapfrogged on reconnect. This service watches Mullvad state
  # and re-inserts our rule right before Mullvad's routing rule after each change.
  systemd.services.tailscale-routing-fix = {
    description = "Keep Tailscale routing rule before Mullvad";
    after = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 pkgs.mullvad pkgs.gawk ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 3;
      ExecStart = pkgs.writeShellScript "tailscale-routing-fix" ''
        insert_rule() {
          # find first Mullvad rule (suppress_prefixlength) and insert before it
          local mullvad_first
          mullvad_first=$(ip rule show | awk '/suppress_prefixlength/{split($0,a,":"); print a[1]; exit}')
          [ -z "$mullvad_first" ] && return
          local our_prio=$((mullvad_first - 1))
          # clean stale rules we added previously
          ip rule show | awk -F: '/to 100\.64\.0\.0\/10 lookup 52/{p=$1+0; if(p<5100) print p}' | \
            while read -r p; do ip rule del to 100.64.0.0/10 lookup 52 priority "$p" 2>/dev/null; done
          ip rule add to 100.64.0.0/10 lookup 52 priority "$our_prio"
        }
        insert_rule
        mullvad status listen | while read -r _; do
          sleep 1
          insert_rule
        done
      '';
    };
  };

  # zsh completions (mullvad-vpn doesn't propagate them from the mullvad CLI package)
  environment.systemPackages = [
    (pkgs.runCommandLocal "mullvad-zsh-completions" {} ''
      mkdir -p $out/share/zsh/site-functions
      cp ${pkgs.mullvad}/share/zsh/site-functions/_mullvad $out/share/zsh/site-functions/
    '')
  ];

  # Tailscale + Docker + Mullvad coexistence nftables rules.
  # ct mark rules run at priority -100 (before Mullvad's chains at priority 0).
  # They set Mullvad's exclusion marks on Tailscale CGNAT and Docker bridge traffic
  # so Mullvad's own "ct mark 0x00000f41 accept" rules pass it through.
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
        # Docker bridge subnets (172.16.0.0/12 covers default bridge + compose networks)
        ip saddr 172.16.0.0/12 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
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

  # Persist VPN credentials and device key across reboots
  environment.persistence."/persist".directories = [
    "/etc/mullvad-vpn"
  ];
}
