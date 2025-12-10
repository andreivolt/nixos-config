{
  writeShellScriptBin,
}:
writeShellScriptBin "dmg-unmount" ''
  hdiutil info | grep "/Volumes" | awk '{print $1}' | xargs -n1 hdiutil detach
''
