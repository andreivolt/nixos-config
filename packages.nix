pkgs:
with pkgs;
  (import ./packages-common.nix pkgs)
  ++ lib.optionals stdenv.hostPlatform.isDarwin (import ./packages-darwin.nix pkgs)
  ++ lib.optionals stdenv.hostPlatform.isLinux (import ./packages-linux.nix pkgs)
