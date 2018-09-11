self: super: with super; {

upgrade = writeShellScriptBin "upgrade" ''
  sudo sh -c '
    (cd /home/avo/proj/nixpkgs && git pull) \
    && nix-channel --update \
    && nixos-rebuild \
      -I nixpkgs=/home/avo/proj/nixpkgs \
      switch --upgrade' '';

}
