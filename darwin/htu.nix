{pkgs, ...}: {
  launchd.user.agents.chrome-history-export = {
    script = ''
      ~/bin/chrome-history-export ~/Google\ Drive/My\ Drive/chrome-history.tsv
    '';
    serviceConfig = {
      StartCalendarInterval = {
        Hour = 3;
        Minute = 0;
      };
      StandardOutPath = "/tmp/chrome-history-export.log";
      StandardErrorPath = "/tmp/chrome-history-export.err";
    };
  };
}
