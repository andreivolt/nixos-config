{
  expect,
  writeScriptBin,
}:
writeScriptBin "nixos-repl" ''
  #!/usr/bin/env ${expect}/bin/expect
  set timeout 119
  spawn -noecho nix --extra-experimental-features repl-flake repl nixpkgs
  expect "nix-repl> " {
    send ":a builtins\n"
    send "pkgs = legacyPackages.${system}\n"
    interact
  }
''
