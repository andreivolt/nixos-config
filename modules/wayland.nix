{
  home-manager.users.avo = { pkgs, ... }: {
    home.packages = with pkgs; [
      wtype # typing automation
    ];
  };
}
