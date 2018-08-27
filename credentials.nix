with import <nixpkgs> {};

builtins.fromJSON (builtins.getEnv "CREDENTIALS")
