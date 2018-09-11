self: super: with super; {

termdo = writeShellScriptBin "termdo" ''
  setsid \
    ${self.avo.terminal}/bin/terminal \
      -e sh -c "$*" '';

}
