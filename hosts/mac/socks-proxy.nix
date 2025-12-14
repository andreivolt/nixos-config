# Persistent SOCKS proxy to ampere (Oracle Cloud)
# Provides a local SOCKS5 proxy on port 1080
{pkgs, ...}: {
  launchd.user.agents.socks-proxy = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.autossh}/bin/autossh"
        "-M" "0"
        "-N"
        "-D" "1080"
        "-o" "ServerAliveInterval=30"
        "-o" "ServerAliveCountMax=3"
        "-o" "ExitOnForwardFailure=yes"
        "ampere"
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
