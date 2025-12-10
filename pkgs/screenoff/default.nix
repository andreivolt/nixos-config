{
  writeShellScriptBin,
  hyprland,
}:
writeShellScriptBin "screenoff" ''
  ${hyprland}/bin/hyprctl dispatch dpms off
''
