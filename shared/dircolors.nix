{
  home-manager.sharedModules = [
    {
      programs.dircolors = {
        enable = true;
        enableZshIntegration = true;
        extraConfig = ''
          # Minimal colors - only dirs, links, executables
          NORMAL 0
          FILE 0
          DIR 34
          LINK 35
          EXEC 32

          # Disable everything else
          FIFO 0
          SOCK 0
          BLK 0
          CHR 0
          ORPHAN 0
          SETUID 0
          SETGID 0
          STICKY_OTHER_WRITABLE 0
          OTHER_WRITABLE 0
          STICKY 0
          CAPABILITY 0
          MULTIHARDLINK 0
          DOOR 0

          # No colors for file extensions
          * 0
        '';
      };
    }
  ];
}
