{ pkgs, ... }:
let
  pacFile = pkgs.writeText "proxy.pac" ''
    function isDomain(host, d) { return host === d || dnsDomainIs(host, "." + d); }
    function FindProxyForURL(url, host) {
      if (dnsDomainIs(host, ".onion")) return "SOCKS5 127.0.0.1:9050";
      if (isDomain(host, "rumble.com")) return "SOCKS5 127.0.0.1:1080";
      if (isDomain(host, "youtube.com") ||
          isDomain(host, "youtube-nocookie.com") ||
          isDomain(host, "googlevideo.com") ||
          isDomain(host, "ytimg.com") ||
          isDomain(host, "ggpht.com"))
        return "SOCKS5 127.0.0.1:1090";
      return "DIRECT";
    }
  '';
  pacBase64 = builtins.readFile (derivation {
    name = "proxy-pac-b64";
    system = pkgs.system;
    builder = "${pkgs.bash}/bin/bash";
    args = [ "-c" "${pkgs.coreutils}/bin/base64 -w0 < ${pacFile} > $out" ];
  });
in {
  # HM concats commandLineArgs with spaces, no quoting — the single quotes
  # protect the semicolon in the data URI from shell interpretation
  home-manager.users.andrei.programs.chromium.commandLineArgs = [
    "'--proxy-pac-url=data:application/x-javascript-config;base64,${pacBase64}'"
  ];
}
