{ lib, ... }:

{
  home-manager.users.avo
    .home.file.".netrc".text =
      lib.concatStringsSep "\n"
        (lib.mapAttrsToList
          (name: value: ''
            machine ${name}
              password ${value.password}
              login ${value.login}
          '')
          (import ./private/credentials.nix).netrc);
}
