self: super: with super; {

awscli = let _ = with (import /home/avo/lib/credentials.nix).aws; ''
  wrapProgram $out/bin/aws \
    --set-default AWS_ACCESS_KEY_ID ${access_key_id} \
    --set-default AWS_SECRET_ACCESS_KEY ${secret_access_key}'';
in hiPrio (stdenv.lib.overrideDerivation awscli (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
