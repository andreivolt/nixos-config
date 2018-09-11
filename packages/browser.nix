self: super: with super; {

browser = writeShellScriptBin "browser" ''
  exec &>/dev/null setsid \
    ${self.wrapped.google-chrome-dev}/bin/google-chrome-unstable \
      "$*"'';

}
