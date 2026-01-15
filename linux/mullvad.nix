# Mullvad VPN with Tailscale coexistence
# After rebuild: mullvad account login <account-number>
# SOCKS5 proxy available at 10.64.0.1:1080 when connected
{pkgs, ...}: {
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

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

  # Persist VPN credentials and device key across reboots
  environment.persistence."/persist".directories = [
    "/etc/mullvad-vpn"
  ];
}
