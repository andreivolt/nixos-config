{
  services.openssh.enable = true;

  users.users.avo
    .openssh.authorizedKeys.keyFiles = [ ./avo.pub ];
}
