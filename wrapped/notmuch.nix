self: super: with super; {

notmuch =
  let conf = lib.generators.toINI {} {
    user = with import /home/avo/lib/credentials.nix; { name = name; primary_email = email.address; };

    search.exclude_tags = "deleted;spam;"; };
  in let _ = ''
    wrapProgram $out/bin/notmuch \
      --add-flags '--config ${writeText "_" conf}' '';
  in hiPrio (stdenv.lib.overrideDerivation notmuch (attrs: {
    buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
    postInstall = attrs.postInstall or "" + _; }));

}
