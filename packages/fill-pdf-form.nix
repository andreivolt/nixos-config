self: super: with super; {

fill-pdf-form = writeShellScriptBin "fill-pdf-form" ''
  exec &>/dev/null setsid \
    ${evince}/bin/evince "$*"'';

}
