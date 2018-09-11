self: super: with super; {

less = let _ = ''
  wrapProgram $out/bin/less \
    --add-flags '--RAW-CONTROL-CHARS' \
    --add-flags '--ignore-case' \
    --add-flags '--no-init' \
    --add-flags '--quit-if-one-screen' '';
in hiPrio (stdenv.lib.overrideDerivation less (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
