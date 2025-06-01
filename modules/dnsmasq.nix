{
  lib,
  pkgs,
  ...
}: let
  localDomains = {
    "test" = "127.0.0.1";
    "mac" = "100.112.239.30";
  };
in {
  services.dnsmasq =
    {
      enable = true;
    }
    // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
      settings.address = lib.mapAttrsToList (domain: ip: "/${domain}/${ip}") localDomains;
    }
    // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin) {
      addresses = localDomains;
    };
}
