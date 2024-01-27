{
  home-manager.users.andrei.home.packages = with pkgs; [ gnash ];

  nixpkgs.config.permittedInsecurePackages = [ "ffmpeg-2.8.17" ];
}
