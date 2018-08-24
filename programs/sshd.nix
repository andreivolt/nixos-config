{
  services.openssh.enable = true;

  users.users.avo
    .openssh.authorizedKeys.keyFiles = [ /etc/nixos/private/ssh-keys/id_rsa.pub ];
}
