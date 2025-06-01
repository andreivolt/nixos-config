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
      pinentryFlavor = "tty";
    };
}
