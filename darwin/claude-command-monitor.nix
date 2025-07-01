{...}: {
  launchd.user.agents.claude-command-monitor.serviceConfig = {
    ProgramArguments = [
      "/Users/andrei/bin/claude-command-monitor"
      "--write-history"
    ];
    WorkingDirectory = "/Users/andrei";
    KeepAlive = true;
    StandardOutPath = "/Users/andrei/.local/state/claude-command-monitor.log";
    StandardErrorPath = "/Users/andrei/.local/state/claude-command-monitor.error.log";
  };
}