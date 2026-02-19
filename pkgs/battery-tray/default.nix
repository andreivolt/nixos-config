{
  lib,
  python3,
  writeShellScriptBin,
}:
let
  python = python3.withPackages (ps: [ ps.dbus-python ps.pygobject3 ]);
in
writeShellScriptBin "battery-tray" ''
  exec ${python}/bin/python3 ${./battery-tray.py}
''
