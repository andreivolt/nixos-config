{

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;

  users.users.avo.extraGroups = [ "docker" ];
}
