{
  home-manager.users.avo.programs.himalaya = {
    enable = true;
    package = with pkgs; pkgs.himalaya.overrideAttrs (oldAttrs: rec {
      src = fetchFromGitHub {
        repo = "himalaya";
        owner = "soywod";
        rev = "fadebf09977df5d5e571d1d9a2f73ccea44390a7";
        sha256 = "1phwl1s9x3k9dpyyqijik2yq3awrzqcf5j32yb26l9lg3szq1scq";
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
        smtp-login = "your.email@gmail.com";
        smtp-passwd-cmd = "cat ~/gdrive/gmail-app-password.txt";
      };
    };
  };
}
