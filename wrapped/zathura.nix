self: super: with super; {

zathura =
  let zathura-custom = zathura.override { useMupdf = true; };
  in let conf = ''
    set incremental-search true
    set window-title-basename true'';
  in let _ = ''
    mkdir -p $out/config && cp ${writeText "_" conf} $out/config

    wrapProgram $out/bin/zathura \
      --add-flags '--config-dir $out/config' '';
  in hiPrio (stdenv.lib.overrideDerivation zathura-custom (attrs: {
    buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
    postInstall = attrs.postInstall or "" + _; }));

}
