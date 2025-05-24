{pkgs, ...}: {
  home-manager.users.andrei.programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      mpris
      mpv-osc-modern
      webtorrent-mpv-hook
    ];
  };
}
