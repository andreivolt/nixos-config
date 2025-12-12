# Persistent SOCKS proxy to ampere (Oracle Cloud)
# Provides a local SOCKS5 proxy on port 1080
{pkgs, ...}: {
  environment.systemPackages = [pkgs.autossh];

  systemd.services.socks-proxy = {
    description = "Persistent SOCKS proxy to ampere";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "andrei";
      ExecStart = "${pkgs.autossh}/bin/autossh -M 0 -N -D 1080 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes ampere";
      Restart = "always";
      RestartSec = "10";
    };
  };
}
