{pkgs, ...}: {
  launchd.user.agents.host-opener = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.bun}/bin/bun"
        "/Users/andrei/Insync/andrei.volt@gmail.com/Google Drive/dev/android-share/host-opener.js"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/tmp/host-opener.err";
      StandardOutPath = "/tmp/host-opener.out";
      EnvironmentVariables = {
        PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin";
      };
    };
  };
}
