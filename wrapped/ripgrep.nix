self: super: with super; {

ripgrep = let _ = ''
  wrapProgram $out/bin/rg \
    --add-flags '--smart-case' \
    --add-flags '--colors=match:fg:yellow --colors=match:style:underline' '';
in hiPrio (stdenv.lib.overrideDerivation ripgrep (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
