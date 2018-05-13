{ config, ... }:

{
  services.openvpn.servers.default = let credentials = import ../private/credentials.nix; in {
    config = "config ${config.users.users.avo.home}/.config/openvpn/conf";
    autoStart = false;
    authUserPass = with credentials.openvpn; { inherit username password; };
  };

  home-manager.users.avo
    .programs.zsh.shellAliases = {
      vpnoff = "sudo systemctl stop openvpn-default";
      vpnon  = "sudo systemctl start openvpn-default";
    };
}
