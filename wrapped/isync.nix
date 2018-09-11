self: super: with super; {

isync =
  let conf = with import /home/avo/lib/credentials.nix; ''
    IMAPAccount main
    Host imap.gmail.com
    User ${email.address}
    Pass ${email.password}
    SSLType IMAPS
    CertificateFile /etc/ssl/certs/ca-certificates.crt

    IMAPStore main-remote
    Account main

    MaildirStore main-local
    Subfolders Verbatim
    Path ~/mail-isync/
    Inbox ~/mail-isync/Inbox

    Channel main
    Master :main-remote:
    Slave :main-local:
    Patterns * ![Gmail]* "[Gmail]/Sent Mail" "[Gmail]/Starred" "[Gmail]/All Mail"
    Create Both
    SyncState *'';
  in let _ = ''
    wrapProgram $out/bin/mbsync \
      --add-flags '--config ${writeText "_" conf}' '';
  in hiPrio (stdenv.lib.overrideDerivation isync (attrs: {
    buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
    postInstall = attrs.postInstall or "" + _; }));

}
