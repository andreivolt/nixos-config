self: super: with super; {

blink-diff = writeShellScriptBin "blink-diff" ''
  ${self.avo.npm-run}/bin/npm-run blink-diff blink-diff "$@"'';

}
