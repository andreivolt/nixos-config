{ config, pkgs, ... }:

let
  emacs-edit-server = let _ = ''
    (use-package edit-server
      :config
      (edit-server-start))

    (use-package writeroom-mode
      :config
      (global-writeroom-mode 1))
  '';
  in with pkgs; writeShellScriptBin "emacs-edit-server" ''
    exec \
      ${avo.emacs}/bin/emacs \
        --fg-daemon=edit-server \
        --load ${writeText "_" _}
  '';

in {
  environment.systemPackages = [ emacs-edit-server ];

  systemd.user.services.emacs-edit-server = {
    wantedBy = [ "default.target" ];
    path = [ emacs-edit-server ];
    script = "source ${config.system.build.setEnvironment} && emacs-edit-server";
    serviceConfig.Restart = "always";
  };
}
