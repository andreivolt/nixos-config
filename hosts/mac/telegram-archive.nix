{...}: {
  launchd.user.agents.telegram-archive.serviceConfig = {
    ProgramArguments = [
      "/Users/andrei/drive/telegram-archive/telegram-archive"
      "telegram.db"
    ];
    WorkingDirectory = "/Users/andrei/drive/telegram-archive";
    StartInterval = 3600;
  };
}