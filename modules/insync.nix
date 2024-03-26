{ pkgs, ... }:

{
  home-manager.users.andrei = { pkgs, ... }: {
    home.packages = with pkgs; [ insync ];
  };

  systemd.user.services.insync = {
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];
    script = "${pkgs.insync}/bin/insync start";
    serviceConfig = { Type = "forking"; Restart = "always"; };
  };
}
