self: super: with super; {

webapp = writeShellScriptBin "webapp" ''
  exec &>/dev/null setsid \
    ${self.wrapped.google-chrome-dev}/bin/google-chrome-unstable \
      --class=webapp \
      --app="$*"'';

}
