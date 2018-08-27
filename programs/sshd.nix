{
  services.openssh.enable = true;

  users.users.avo
    .openssh.authorizedKeys.keyFiles = [ /home/avo/.ssh/id_rsa.pub ];
}
