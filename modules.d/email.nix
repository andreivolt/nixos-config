{ pkgs, ... }:

{
  # systemd.user.services.emacs-notmuch = {
  #   wantedBy = [ "default.target" ];
  #   path = [ pkgs.avo.emacs-notmuch-server ];
  #   script = "source ${config.system.build.setEnvironment} && emacs-notmuch-server";
  #   serviceConfig.Restart = "always";
  # };

  services.offlineimap = {
    enable = true;
    package = pkgs.wrapped.offlineimap;
  };
}
