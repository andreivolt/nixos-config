self: super: with super; {

rebuild = writeShellScriptBin "rebuild" ''
  sudo \
    nixos-rebuild \
      -I nixpkgs=$HOME/proj/nixpkgs \
      switch --upgrade'';

}
