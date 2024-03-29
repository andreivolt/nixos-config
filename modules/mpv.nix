{ pkgs, ... }:

{
  home-manager.users.andrei = { pkgs, ... }: {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        mpris
        webtorrent-mpv-hook
      ];
      config = {
        input-ipc-server = "/tmp/mpvsocket";
        geometry = "30%";
        script-opts = "osc-vidscale=no"; # prevent UI scaling
        audio-display = false; # don't display album art
      };
    };
  };
}
