{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.avo.extraGroups = [ "docker" ];

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 100000;
}
