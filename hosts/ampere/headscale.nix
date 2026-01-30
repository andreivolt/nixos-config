# Headscale - self-hosted Tailscale control server
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;

    settings = {
      server_url = "https://hs.avolt.net";

      # DNS configuration for the tailnet
      dns = {
        magic_dns = true;
        base_domain = "tail.avolt.net";
        nameservers.global = [
          "https://dns.nextdns.io/1c27d6"
        ];
        extra_records = [
          { name = "pw.avolt.net"; type = "A"; value = "100.64.0.1"; }
        ];
      };

      # IP prefixes for the tailnet
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };

      # Disable open registration - use CLI to create users
      # Run: headscale users create <username>
      # Then: headscale preauthkeys create --user <username>

      # DERP (relay) configuration
      derp = {
        server = {
          enabled = true;
          region_id = 999;
          region_code = "headscale";
          region_name = "Headscale Embedded DERP";
          stun_listen_addr = "0.0.0.0:3478";
        };
        urls = [];
        paths = [];
        auto_update_enabled = true;
        update_frequency = "24h";
      };

      # Logging
      log = {
        format = "text";
        level = "info";
      };

      # Database - using SQLite (sufficient for personal use)
      database = {
        type = "sqlite";
        sqlite.path = "/var/lib/headscale/db.sqlite";
      };

      # Noise protocol for better security
      noise.private_key_path = "/var/lib/headscale/noise_private.key";

      # Ephemeral node cleanup
      ephemeral_node_inactivity_timeout = "30m";

      # Policy/ACLs - default allow all (null = no policy file)
      policy.path = null;
    };
  };

  # Nginx reverse proxy with HTTPS
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts."hs.avolt.net" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
        '';
      };
    };
  };

  # Open firewall for STUN
  networking.firewall.allowedUDPPorts = [3478];

  # Headscale CLI available system-wide
  environment.systemPackages = [pkgs.headscale];

  # Create systemd service dependency
  systemd.services.headscale = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };
}
