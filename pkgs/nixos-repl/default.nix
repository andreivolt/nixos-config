{
  expect,
  writeScriptBin,
  stdenv,
}:
writeScriptBin "nixos-repl" ''
  #!/usr/bin/env ${expect}/bin/expect
  set timeout 119
  spawn -noecho nix --extra-experimental-features repl-flake repl nixpkgs
  expect "nix-repl> " {
    send ":a builtins\n"
    send "pkgs = legacyPackages.${stdenv.hostPlatform.system}\n"
    interact
  }
''
