self: super: with super; {

offlineimap =
  let account = "avolt.net"; in
  let conf = {
    general.accounts = account;

    "Account ${account}" = {
      localrepository = "${account}_local"; remoterepository = "${account}_remote";
      postsynchook = "${self.wrapped.notmuch}/bin/notmuch new";
      realdelete = "yes"; };

    "Repository ${account}_local" = {
      localfolders = "~/mail";
      type = "Maildir";
      nametrans = "lambda folder: folder == 'INBOX' and 'INBOX' or ('INBOX.' + folder)"; };

    "Repository ${account}_remote" = with import /home/avo/lib/credentials.nix; {
      type = "Gmail";
      remoteuser = email.address; remotepass = email.password;
      sslcacertfile = "/etc/ssl/certs/ca-certificates.crt";
      nametrans = "lambda folder: {'[Gmail]/All Mail': 'archive',}.get(folder, folder)";
      folderfilter = "lambda folder: folder == '[Gmail]/All Mail'";
      realdelete = "yes";
      synclabels = "yes"; }; };
  in let _ = ''
    wrapProgram $out/bin/offlineimap \
      --add-flags '-c ${writeText "_" (lib.generators.toINI {} conf)}' '';
  in hiPrio (stdenv.lib.overrideDerivation offlineimap (attrs: {
    buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
    postInstall = attrs.postInstall or "" + _; }));

}
