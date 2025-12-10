{
  writeShellScriptBin,
  stdenv,
  imagemagick,
}:
writeShellScriptBin "pngview" (
  if stdenv.hostPlatform.isDarwin
  then ''
    exec open -a Preview.app -f
  ''
  else ''
    exec ${imagemagick}/bin/display -
  ''
)
