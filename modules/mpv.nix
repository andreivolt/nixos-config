{ pkgs, ... }:

{
  home-manager.users.avo = { pkgs, ... }: {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [ mpris ];
      config = {
        input-ipc-server = "/tmp/mpvsocket";
        geometry = "25%";
        script-opts = "osc-vidscale=no";
      };
    };
  };
}
