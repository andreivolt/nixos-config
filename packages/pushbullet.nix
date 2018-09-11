self: super: with super; {

pushbullet = writeShellScriptBin "pushbullet" ''
  exec &>/dev/null setsid \
    ${self.wrapped.google-chrome-dev}/bin/google-chrome-unstable \
      --class pushbullet \
      --app='chrome-extension://chlffgpmiacpedhhbkiomidkjlcfhogd/panel.html#popout' '';

}
