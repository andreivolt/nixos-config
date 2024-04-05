{ pkgs, ... }:

{
  home-manager.users.andrei.programs.himalaya = {
    enable = true;
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
        imap-passwd-cmd = "cat ~/drive/gmail-app-password.txt";

        smtp-host = "smtp.gmail.com";
        smtp-port = 465;
        smtp-login = "andrei.volt@gmail.com";
        smtp-passwd-cmd = "cat ~/drive/gmail-app-password.txt";
      };
    };
  };
}
