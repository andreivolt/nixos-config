{ lib, ... }:

{
  home-manager.users.avo
    .home.file.".netrc".text =
      lib.concatStringsSep "\n"
        (lib.mapAttrsToList
          (machine: credentials: ''
            machine ${machine}
              password ${credentials.password}
              login ${credentials.login}
          '')
          (import ./private/credentials.nix).netrc);
}
