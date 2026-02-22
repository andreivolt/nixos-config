{
  lib,
  python3,
  mullvad,
  writeShellScriptBin,
  andrei,
}:
let
  python = python3.withPackages (ps: [ ps.dbus-python ps.pygobject3 ]);
  iconThemePath = "${andrei.phosphor-icon-theme}/share/icons/Phosphor";
in
writeShellScriptBin "mullvad-tray" ''
  export ICON_THEME_PATH="${iconThemePath}"
  export PATH="${lib.makeBinPath [ mullvad ]}:$PATH"
  exec ${python}/bin/python3 ${./mullvad-tray.py}
''
