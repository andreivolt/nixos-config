{
  services.openssh.enable = true;

  users.users.avo
    .openssh.authorizedKeys.keyFiles = [ ./private/ssh-keys/id_rsa.pub ];
}
