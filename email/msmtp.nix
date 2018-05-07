{ config, lib, pkgs, ... }:

let
  email = (import ../credentials.nix).email;
  accounts = email.accounts;

in {
  environment.systemPackages = with pkgs; [ msmtp ];

  home-manager.users.avo
    .home.file.".msmtprc".text = ''
      defaults
      auth            on
      tls             on
      tls_trust_file  /etc/ssl/certs/ca-certificates.crt

      ${lib.concatStringsSep "\n" (map (account: ''
        account  ${if account ? name then account.name else account.address}
        host     ${if account ? type && account.type == "gmail" then "smtp.gmail.com" else account.host}
        port     ${if account ? type && account.type == "gmail" then "587" else account.port}
        user     ${if account ? type && account.type == "gmail" then account.address else account.user}
        password ${account.password}
        from     ${if account ? type && account.type == "gmail" then account.address else account.from}
      '') email.accounts)}

      account default: ${email.primary_address}
    '';

  environment.etc."mailrc".text = ''
    set sendmail=${pkgs.msmtp}/bin/msmtp"
  '';

  home-manager.users.avo
    .programs.zsh.shellAliases.msmtp = with config.home-manager.users.avo;
      "${xdg.cacheHome}/mstmp/msmtprc";
}
