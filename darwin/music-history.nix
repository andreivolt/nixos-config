{...}: {
  launchd.user.agents.music-history.serviceConfig = {
    ProgramArguments = [
      "/Users/andrei/drive/music-history/lastfm-sync"
      "music-history.db"
    ];
    WorkingDirectory = "/Users/andrei/drive/music-history";
    StartInterval = 3600;
  };
}