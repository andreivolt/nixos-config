self: super: with super; {

openssh =
  let ssh_identity = (import /home/avo/lib/credentials.nix).ssh_keys.private;
  in let _ = ''
    wrapProgram $out/bin/ssh \
      --add-flags '-i ${writeText "ssh_identity" ssh_identity}' '';
  in hiPrio (stdenv.lib.overrideDerivation openssh (attrs: {
    buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
    postInstall = attrs.postInstall or "" + _; }));

}
