self: super: with super; {

display-off = writeShellScriptBin "display-off" ''
  xset -dpms
  xset dpms force off
    ${evince}/bin/evince "$*" '';

}
