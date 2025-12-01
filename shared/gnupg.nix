{
  lib,
  pkgs,
  ...
}: {
  programs.gnupg.agent =
    {
      enable = true;
      enableSSHSupport = true;
    }
    // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
      pinentryPackage = pkgs.pinentry-all;
    };
}
