self: super: with super; {

google-chrome-dev = let _ = ''
  wrapProgram $out/bin/google-chrome-unstable \
    --add-flags '--remote-debugging-port=9222' \
    --add-flags '--no-default-browser-check' '';
in hiPrio (stdenv.lib.overrideDerivation google-chrome-dev (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
