{ lib, ... }:
let
  pacScript = lib.concatStringsSep " " [
    "function FindProxyForURL(url, host) {"
    "if (shExpMatch(host, '*.onion')) return 'SOCKS5 127.0.0.1:9050';"
    "if (shExpMatch(host, '*.rumble.com')) return 'SOCKS5 127.0.0.1:1080';"
    "return 'DIRECT';"
    "}"
  ];
in {
  programs.chromium.extraOpts = {
    ProxySettings = {
      ProxyMode = "pac_script";
      ProxyPacUrl = "data:application/x-ns-proxy-autoconfig,${pacScript}";
    };
  };
}
