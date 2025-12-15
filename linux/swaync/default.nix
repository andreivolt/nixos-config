{ pkgs, ... }: {
  # Install swaync package
  environment.systemPackages = [ pkgs.swaynotificationcenter ];

  # SwayNotificationCenter service - Obsidian Aurora theme
  home-manager.users.andrei = { ... }: {
    services.swaync = {
      enable = true;
      settings = {
        cssPriority = "user";
      };
      style = builtins.readFile ./style.css;
    };
  };
}
