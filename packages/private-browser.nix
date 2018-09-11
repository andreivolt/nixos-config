self: super: with super; {

private-browser = writeShellScriptBin "private-browser" ''
  exec &>/dev/null setsid \
    ${self.wrapped.google-chrome-dev}/bin/google-chrome-unstable \
      --incognito \
      "$@"'';

}
