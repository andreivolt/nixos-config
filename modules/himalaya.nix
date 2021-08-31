{ pkgs, ... }:

{
  home-manager.users.avo.programs.himalaya = {
    enable = true;
    package = with pkgs; himalaya.overrideAttrs (oldAttrs: rec {
      src = fetchFromGitHub {
        repo = "himalaya";
        owner = "soywod";
        rev = "608057b23bcd067e6f5fe130c6e395655432a448";
        sha256 = "0h055fdd5mnla5s8yxrbr52l3bnmccs085gc1wqd5g40v4rln273";
      };
    });
    settings = {
      name = "Andrei Volt";
      downloads-dir = "/home/avo/gdrive";
      signature = "";

      gmail = {
        default = true;
        email = "andrei.volt@gmail.com";

        imap-host = "imap.gmail.com";
        imap-port = 993;
        imap-login = "andrei.volt@gmail.com";
        imap-passwd-cmd = "cat ~/gdrive/gmail-app-password.txt";

        smtp-host = "smtp.gmail.com";
        smtp-port = 465;
        smtp-login = "andrei.volt@gmail.com";
        smtp-passwd-cmd = "cat ~/gdrive/gmail-app-password.txt";
      };
    };
  };
}
