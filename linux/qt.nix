{pkgs, ...}: {
  home-manager.users.andrei = {
    # Use home-manager's qt module for proper dark theme
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
