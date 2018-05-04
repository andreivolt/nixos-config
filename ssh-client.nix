{
  home-manager.users.avo
    .programs.ssh = {
      enable = true;

      controlMaster  = "auto";
      controlPath    = "/tmp/ssh-%u-%r@%h:%p";
      controlPersist = "0";
    };
}
