# Mullvad VPN with Tailscale coexistence
# After rebuild: mullvad account login <account-number>
# SOCKS5 proxy available at 10.64.0.1:1080 when connected
{pkgs, ...}: {
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

  # Persist VPN credentials and device key across reboots
  environment.persistence."/persist".directories = [
    "/etc/mullvad-vpn"
  ];
}
