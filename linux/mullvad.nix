# Mullvad VPN with Tailscale coexistence
# After rebuild: mullvad account login <account-number>
# SOCKS5 proxy available at 10.64.0.1:1080 when connected
{pkgs, config, lib, ...}: let
  nextdnsStart = pkgs.writeShellScript "nextdns-mullvad-excluded" ''
    exec ${pkgs.mullvad-vpn}/bin/mullvad-exclude \
      ${pkgs.nextdns}/bin/nextdns run \
        -config "$(cat ${config.sops.secrets."nextdns/setup_id".path})" \
        -listen 127.0.0.1:5354 \
        -report-client-info
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
  '';

  # zsh completions (mullvad-vpn doesn't propagate them from the mullvad CLI package)
  environment.systemPackages = [
    (pkgs.runCommandLocal "mullvad-zsh-completions" {} ''
      mkdir -p $out/share/zsh/site-functions
      cp ${pkgs.mullvad}/share/zsh/site-functions/_mullvad $out/share/zsh/site-functions/
    '')
  ];

  # Allow Tailscale traffic to bypass Mullvad tunnel
  # Marks packets to Tailscale's CGNAT range (100.64.0.0/10) with Mullvad's exclusion marks
  # https://theorangeone.net/posts/tailscale-mullvad/
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

  # Auto-start Mullvad GUI in tray (NixOS user service to avoid restart on rebuild)
  systemd.user.services.mullvad-gui = {
    description = "Mullvad VPN GUI";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad-vpn";
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
