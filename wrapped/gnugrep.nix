self: super: with super; {

gnugrep = let _ = ''
  wrapProgram $out/bin/grep \
    --set-default GREP_COLOR 1 \
    --add-flags '--color=auto' '';
in hiPrio (stdenv.lib.overrideDerivation gnugrep (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
