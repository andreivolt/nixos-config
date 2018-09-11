self: super: with super; {

open = writeShellScriptBin "open" ''
  setsid &>/dev/null \
    ${xdg_utils}/bin/xdg-open "$*" '';

}
