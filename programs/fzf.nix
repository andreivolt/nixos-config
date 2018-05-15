{
  home-manager.users.avo.programs.fzf = {
    enable = true;

    defaultOptions = [
      "--color" "bw"
    ];

    enableZshIntegration = false;
  };
}
