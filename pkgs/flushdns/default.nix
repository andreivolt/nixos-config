{
  lib,
  writeShellScriptBin,
  stdenv,
  systemd,
  procps,
}:
writeShellScriptBin "flushdns" (
  if stdenv.hostPlatform.isDarwin
  then ''
    sudo killall -HUP mDNSResponder
  ''
  else ''
    # Try systemd-resolved first, then dnsmasq
    if ${procps}/bin/pgrep -x systemd-resolved >/dev/null 2>&1; then
      sudo ${systemd}/bin/resolvectl flush-caches
    elif ${procps}/bin/pgrep -x dnsmasq >/dev/null 2>&1; then
      sudo killall -HUP dnsmasq
    else
      echo "No supported DNS resolver found (systemd-resolved or dnsmasq)"
      exit 1
    fi
  ''
)
