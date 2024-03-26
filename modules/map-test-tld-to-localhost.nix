{ lib, pkgs, ... }:

let
  domain = "test";
  ip = "127.0.0.1";
in
{
  services.dnsmasq = {
    enable = true;
  } // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
    settings = { address = "/${domain}/${ip}"; };
  } // lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin) {
    addresses = { "${domain}" = ip; };
  };
}
