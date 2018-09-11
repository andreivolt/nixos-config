self: super: with super; {

fzf = let _ = ''
  wrapProgram $bin/bin/fzf \
    --add-flags '--color bg:15,fg:8,bg+:4,fg+:0,hl:3,hl+:3,info:15,pointer:12,prompt:8' \
    --add-flags '--no-bold' '';
in hiPrio (stdenv.lib.overrideDerivation fzf (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postFixup = attrs.postFixup or "" + _; }));

}
