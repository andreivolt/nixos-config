{pkgs, ...}:
let
  exportScript = pkgs.writers.writePython3 "chrome-history-export" {}
    (builtins.readFile ../../shared/scripts/chrome-history-export.py);
in {
  launchd.user.agents.chrome-history-export = {
    script = "${exportScript}";
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
