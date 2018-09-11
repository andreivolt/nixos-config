self: super: with super; {

chmodx = writeShellScriptBin "+x" ''
  chmod +x "$*" '';

}
