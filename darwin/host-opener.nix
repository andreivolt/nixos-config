{pkgs, ...}: {
  launchd.user.agents.host-opener = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.bun}/bin/bun"
        "/Users/andrei/Library/CloudStorage/GoogleDrive-andrei.volt@gmail.com/My Drive/android-share-api/host-opener.js"
      ];
      WorkingDirectory = "/Users/andrei/Library/CloudStorage/GoogleDrive-andrei.volt@gmail.com/My Drive/android-share-api";
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/tmp/host-opener.err";
      StandardOutPath = "/tmp/host-opener.out";
    };
  };
}