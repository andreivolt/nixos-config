{
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  users.users.andrei.extraGroups = ["docker"];
}
