{pkgs, ...}: {
  home-manager.users.andrei.home.packages = [pkgs.insync];

  systemd.user.services.insync = {
    after = ["network.target"];
    wantedBy = ["default.target"];
    script = "${pkgs.insync}/bin/insync start";
    serviceConfig = {
      Type = "forking";
      Restart = "always";
    };
  };
}
