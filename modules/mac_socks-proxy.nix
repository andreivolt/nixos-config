{pkgs, ...}: {
  launchd.user.agents.autossh-persistent-socks = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.autossh}/bin/autossh"
        "-M"
        "20000"
        "-D"
        "1080"
        "-N"
        "oracle"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/autossh.err";
      StandardOutPath = "/tmp/autossh.out";
    };
  };
}
