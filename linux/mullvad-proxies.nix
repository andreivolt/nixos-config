# Local proxies that bypass the Mullvad tunnel
# SOCKS5 on 127.0.0.1:1090, HTTP on 127.0.0.1:1091
{ pkgs, ... }: {
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
}
