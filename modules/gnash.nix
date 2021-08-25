{
  home-manager.users.avo.home.packages = with pkgs; [ gnash ];

  nixpkgs.config.permittedInsecurePackages = [ "ffmpeg-2.8.17" ];
}
