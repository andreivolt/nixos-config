self: super: with super; {

guesslang = writeShellScriptBin "guesslang" ''
  ${self.avo.npm-run}/bin/npm-run franc-cli franc "$@"'';

}
