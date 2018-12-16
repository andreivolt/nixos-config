{
  services.openssh.enable = true;

  users.users.avo.openssh.authorizedKeys.keys = [ (import /home/avo/lib/credentials.nix).ssh_keys.public ];
}
