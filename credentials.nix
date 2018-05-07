with import <nixpkgs> {};

let
  credentials = builtins.fromJSON (builtins.readFile ./private/credentials.json);
in
  credentials //
    { googleAccount = lib.findFirst (account: account.address == "andrei.volt@gmail.com") null (import ./credentials.nix).email.accounts; }
