{...}: {
  launchd.user.agents.telegram-open.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/open"
      "-a"
      "Telegram"
    ];
    StartCalendarInterval = [{
      Hour = 8;
      Minute = 0;
    }];
  };
}
