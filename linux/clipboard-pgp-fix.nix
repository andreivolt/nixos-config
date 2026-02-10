# Auto-convert application/pgp-encrypted clipboard to text/plain for browser compatibility
{ pkgs, ... }:
{
  home-manager.sharedModules = [{
    systemd.user.services.clipboard-pgp-fix = {
      Unit = {
        Description = "Convert PGP clipboard to text/plain";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type application/pgp-encrypted --watch ${pkgs.wl-clipboard}/bin/wl-copy --type text/plain";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  }];
}
