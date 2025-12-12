{pkgs, ...}: {
  home-manager.sharedModules = [
    ({config, ...}: {
      programs.zsh = {
        enable = true;
        enableCompletion = false; # handled in completion.zsh
        initContent = "source ~/.config/zsh/rc.zsh";
      };

      home.file = {
        ".zprofile".source = ./zsh/zprofile;

        # Symlink plugins from nixpkgs to expected locations
        ".local/share/zsh/plugins/zsh-defer".source =
          "${pkgs.zsh-defer}/share/zsh-defer";
        ".local/share/zsh/plugins/powerlevel10k".source =
          "${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k";
        ".local/share/zsh/plugins/autopair".source =
          "${pkgs.zsh-autopair}/share/zsh/zsh-autopair";
        ".local/share/zsh/plugins/autosuggestions".source =
          "${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions";
        ".local/share/zsh/plugins/nix-shell".source =
          "${pkgs.zsh-nix-shell}/share/zsh/plugins/zsh-nix-shell";
        ".local/share/zsh/plugins/fast-syntax-highlighting".source =
          "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
        ".local/share/zsh/plugins/history-substring-search".source =
          "${pkgs.zsh-history-substring-search}/share/zsh/plugins/zsh-history-substring-search";
      };

      xdg.configFile = {
        "zsh/rc.zsh".source = ./zsh/rc.zsh;
        "zsh/prompt.zsh".source = ./zsh/prompt.zsh;
        "zsh/p10k.zsh".source = ./zsh/p10k.zsh;
        "zsh/vi.zsh".source = ./zsh/vi.zsh;
        "zsh/completion.zsh".source = ./zsh/completion.zsh;
        "zsh/fzf.zsh".source = ./zsh/fzf.zsh;
        "zsh/autopair.zsh".source = ./zsh/autopair.zsh;
        "zsh/autosuggestions.zsh".source = ./zsh/autosuggestions.zsh;
        "zsh/history-search.zsh".source = ./zsh/history-search.zsh;
        "zsh/history-search/history-search.zsh".source = ./zsh/history-search/history-search.zsh;
        "zsh/history-search/history-search".source = ./zsh/history-search/history-search;
        "zsh/tmux.zsh".source = ./zsh/tmux.zsh;
        "zsh/darwin.zsh".source = ./zsh/darwin.zsh;
        "zsh/termux.zsh".source = ./zsh/termux.zsh;
        "zsh/preview" = {
          source = ./zsh/preview;
          executable = true;
        };
      };

      home.activation.createZshDirs = ''
        mkdir -p ~/.cache/zsh
        mkdir -p ~/.local/share/zsh
        mkdir -p ~/.local/state/zsh
      '';
    })
  ];
}
