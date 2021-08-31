{ pkgs, ... }:

{
  home-manager.users.avo = { pkgs, ... }: {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [ mpris ];
      config = {
        input-ipc-server = "/tmp/mpvsocket";
        geometry = "30%";
        script-opts = "osc-vidscale=no"; # prevent UI scaling
        audio-display = false; # don't display album art
      };
    };
  };
}
