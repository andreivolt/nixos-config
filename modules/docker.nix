{

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.extraOptions = "--experimental";

  users.users.avo.extraGroups = [ "docker" ];
}
