{
  writeShellScriptBin,
  hyprland,
}:
writeShellScriptBin "screenoff" ''
  sleep 0.5 && ${hyprland}/bin/hyprctl dispatch dpms off
''
