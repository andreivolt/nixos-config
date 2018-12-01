self: super: with super; {

mpv = let _ = ''
  wrapProgram $out/bin/mpv \
    --add-flags '--hwdec=vdpau' \
    --add-flags '--profile=opengl-hq' '';
in hiPrio (stdenv.lib.overrideDerivation mpv (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postFixup = attrs.postFixup or "" + _; }));

}
