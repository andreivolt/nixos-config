{ config, lib, ... }:

{
  programs.ssh.extraConfig = ''
    Host *
      ControlMaster auto
      ControlPath /tmp/ssh-%u-%r@%h:%p
      ControlPersist 0
  '';
}
