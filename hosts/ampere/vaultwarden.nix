# Vaultwarden - self-hosted Bitwarden-compatible password manager
# Tailscale-only: DNS points to Tailscale IP, ACME via DNS-01 (DNSimple)
{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.secrets.vaultwarden_admin_token = {
    sopsFile = ../../secrets/vaultwarden.yaml;
    key = "admin_token";
  };

  sops.secrets.dnsimple_token = {
    sopsFile = ../../secrets/vaultwarden.yaml;
    key = "dnsimple_token";
  };

  sops.templates."vaultwarden-env" = {
    content = ''
      ADMIN_TOKEN=${config.sops.placeholder.vaultwarden_admin_token}
    '';
  };

  sops.templates."dnsimple-acme-env" = {
    content = ''
      DNSIMPLE_OAUTH_TOKEN=${config.sops.placeholder.dnsimple_token}
    '';
  };

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.templates."vaultwarden-env".path;
    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      DOMAIN = "https://pw.avolt.net";
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;
      SHOW_PASSWORD_HINT = false;
    };
  };

  # DNS-01 ACME via DNSimple (no public HTTP needed)
  security.acme.certs."pw.avolt.net" = {
    dnsProvider = "dnsimple";
    credentialsFile = config.sops.templates."dnsimple-acme-env".path;
  };

  # Nginx reverse proxy with HTTPS
  services.nginx.virtualHosts."pw.avolt.net" = {
    forceSSL = true;
    useACMEHost = "pw.avolt.net";

    extraConfig = ''
      allow 100.64.0.0/10;
      allow fd7a:115c:a1e0::/48;
      deny all;
    '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:8222";
      proxyWebsockets = true;
    };
  };

  # Allow nginx to read DNS-01 ACME certs
  users.users.nginx.extraGroups = ["acme"];
}
