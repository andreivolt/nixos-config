{ pkgs, ... }:

{
  # catt serves local files on a random port in 45000-47000
  networking.firewall.allowedTCPPortRanges = [{ from = 45000; to = 47000; }];

  # Route multicast out LAN interface for Chromecast mDNS discovery
  # Mullvad's firewall allows multicast (224.0.0.0/24, 239.0.0.0/8) but without
  # an explicit route, packets go through the default route into the VPN tunnel
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "multicast-route" ''
      if [ "$2" = "up" ]; then
        case "$1" in
          wlan*|eth*|en*)
            ip route replace 224.0.0.0/4 dev "$1"
            ;;
        esac
      fi
    '';
  }];
}
