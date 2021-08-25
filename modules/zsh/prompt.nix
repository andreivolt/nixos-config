{
  home-manager.users.avo = { pkgs, ...}: {
    # programs.zsh.initExtra = "source ${./prompt.zsh}";

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };
  };
}
