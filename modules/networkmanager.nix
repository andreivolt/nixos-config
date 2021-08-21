{
  networking.networkmanager.enable = true;

  users.users.avo.extraGroups = [ "networkmanager" ];
}
