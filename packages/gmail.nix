self: super: with super; {

gmail = writeShellScriptBin "gmail" ''
  ${self.avo.webapp}/bin/webapp https://mail.google.com/mail/u/1'';

}
