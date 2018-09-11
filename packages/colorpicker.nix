self: super: with super; {

colorpicker = writeShellScriptBin "colorpicker" ''
  ${gcolor3}/bin/gcolor3 | xsel -b'';

}
