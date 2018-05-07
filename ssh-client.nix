{ config, lib, ... }:

{
  home-manager.users.avo
    .programs.ssh = {
      enable = true;

      controlMaster  = "auto";
      controlPath    = "/tmp/ssh-%u-%r@%h:%p";
      controlPersist = "0";
    };


  home-manager.users.avo
    .home.file = builtins.listToAttrs (map (name: lib.nameValuePair (".ssh/" + name)
                                                                    { text = builtins.readFile (./private/ssh-keys +("/" + name)); })
                                           (lib.attrNames (builtins.readDir ./private/ssh-keys)));

}
