{
  lib,
  writeShellScriptBin,
  stdenv,
  hyprlock,
}:
writeShellScriptBin "lock" (
  if stdenv.hostPlatform.isDarwin
  then ''
    pmset displaysleepnow
    m lock
  ''
  else ''
    ${lib.getExe hyprlock}
  ''
)
