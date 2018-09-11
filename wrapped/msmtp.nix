self: super: with super; {

msmtp = let _ = with import /home/avo/lib/credentials.nix; ''
  wrapProgram $out/bin/msmtp \
    --add-flags '--auth=on --tls=on --tls-trust-file /etc/ssl/certs/ca-certificates.crt' \
    --add-flags '--host=smtp.gmail.com --port=587' \
    --add-flags '--user=${email.address} --passwordeval="echo ${email.password}"' \
    --add-flags '--auto-from' '';
in hiPrio (stdenv.lib.overrideDerivation msmtp (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
