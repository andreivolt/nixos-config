{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.avo.extraGroups = [ "docker" ];
}
