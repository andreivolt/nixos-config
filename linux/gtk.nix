{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = with pkgs; [
      tela-icon-theme
      noto-fonts
    ];

    gtk = {
      enable = true;
      theme.name = "Breeze-Dark";
      iconTheme.name = "Tela-dark";
      font = {
        name = "Noto Sans";
        size = 10;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };
  };
}
