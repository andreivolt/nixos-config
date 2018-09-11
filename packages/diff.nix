self: super: with super; {

diff = writeShellScriptBin "diff" ''
  ${wdiff}/bin/wdiff -n $@ | ${colordiff}/bin/colordiff '';

}
