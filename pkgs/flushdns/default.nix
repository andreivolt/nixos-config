{
  lib,
  writeShellScriptBin,
  stdenv,
  systemd,
}:
writeShellScriptBin "flushdns" (
  if stdenv.hostPlatform.isDarwin
  then ''
    sudo killall -HUP mDNSResponder
  ''
  else ''
    sudo ${systemd}/bin/systemd-resolve --flush-caches
  ''
)
