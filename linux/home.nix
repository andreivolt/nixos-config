# Shared home-manager config for linux systems
# extraPackagesFile: optional file with additional packages (e.g. linux/packages-extra.nix)
{ config, inputs, extraPackagesFile ? null }:

{pkgs, ...}: {
  imports = [
    ../shared/rust-script-warmer.nix
    inputs.vicinae.homeManagerModules.default
  ];

  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config = config.nixpkgs.config;
  nixpkgs.overlays = config.nixpkgs.overlays;

  home.packages =
    (import "${inputs.self}/packages.nix" pkgs)
    ++ (if extraPackagesFile != null then import extraPackagesFile pkgs else []);

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    initContent = "source ~/.config/zsh/rc.zsh";
  };

  services.playerctld.enable = true;
  services.wob.enable = true;
  services.cliphist.enable = true;
  services.swaync.enable = true;
  services.network-manager-applet.enable = true;
  services.trayscale.enable = true;
  services.vicinae = {
    enable = true;
    autoStart = true;
  };

  # Custom systemd services
  systemd.user.services.eww = {
    Unit = {
      Description = "Eww daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
      ExecStartPost = "${pkgs.eww}/bin/eww open bar";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.eww-hyprland-listener = {
    Unit = {
      Description = "EWW Hyprland workspace listener";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "eww.service" ];
      Requires = [ "eww.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "%h/.config/eww/scripts/hyprland-listener";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.lan-mouse = {
    Unit = {
      Description = "Lan Mouse - mouse/keyboard sharing";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse --daemon";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "~/documents";
    download = "~/downloads";
  };
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = let
    browser = "firefox";
  in {
    "application/pdf" = "org.pwmt.zathura.desktop";
    "image/jpeg" = "imv.desktop";
    "image/png" = "imv.desktop";
    "inode/directory" = "thunar.desktop";
    "text/html" = "${browser}.desktop";
    "text/plain" = "sublime_text.desktop";
    "video/mp4" = "mpv.desktop";
    "x-scheme-handler/http" = "${browser}.desktop";
    "x-scheme-handler/https" = "${browser}.desktop";
  };
  xdg.configFile."mimeapps.list".force = true;
}
