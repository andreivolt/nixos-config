# Linux-specific mpv configuration
# The shared mpv module (../shared/mpv.nix) provides the base configuration.
# This file can add Linux-only overrides if needed.
{pkgs, ...}: {
  imports = [../shared/mpv];

  # Linux-specific additions (webtorrent)
  home-manager.sharedModules = [
    {
      programs.mpv.scripts = with pkgs.mpvScripts; [
        webtorrent-mpv-hook
      ];
    }
  ];
}
