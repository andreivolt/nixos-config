{ pkgs, ... }:

{
  home-manager.users.andrei = { pkgs, ... }: {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        mpris
        webtorrent-mpv-hook
        mpv-osc-modern
      ];
      config = {
        input-ipc-server = "/tmp/mpvsocket";
        geometry = "30%";
        script-opts = "osc-vidscale=no";
        audio-display = false;
        
        osc = "no";
        
        "[Idle]" = {
          "profile-cond" = "p['idle-active']";
          "profile-restore" = "copy-equal";
          "title" = "' '";
          "keepaspect" = "no";
          "background" = "1";
        };
      };
    };
  };
}
