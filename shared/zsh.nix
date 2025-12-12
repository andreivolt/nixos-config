{pkgs, ...}: let
  zsh-history-search = pkgs.callPackage ../pkgs/zsh-history-search {};
in {
  home-manager.sharedModules = [
    ({config, ...}: {
      programs.zsh = {
        enable = true;
        enableCompletion = false; # handled in completion.zsh
        initContent = ''
          source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh

          source ~/.config/zsh/rc.zsh

          source ${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme

          zsh-defer source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
          zsh-defer autopair-init

          export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
          zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

          zsh-defer source ${pkgs.zsh-nix-shell}/share/zsh/plugins/zsh-nix-shell/nix-shell.plugin.zsh
          zsh-defer source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
        '';
      };

      home.file.".zprofile".source = ./zsh/zprofile;

      xdg.configFile = {
        "zsh/rc.zsh".source = ./zsh/rc.zsh;
        "zsh/prompt.zsh".source = ./zsh/prompt.zsh;
        "zsh/p10k.zsh".source = ./zsh/p10k.zsh;
        "zsh/vi.zsh".source = ./zsh/vi.zsh;
        "zsh/completion.zsh".source = ./zsh/completion.zsh;
        "zsh/fzf.zsh".source = ./zsh/fzf.zsh;
        "zsh/history-search.zsh".source = ./zsh/history-search.zsh;
        "zsh/history-search/history-search.zsh".text = ''
          (( ! ''${+ZSH_FZF_HISTORY_SEARCH_BIND} )) &&
          typeset -g ZSH_FZF_HISTORY_SEARCH_BIND='^r'

          (( ! ''${+ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH} )) &&
          typeset -g ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH=1

          (( ! ''${+ZSH_HISTORY_RELATIVE_DATES} )) &&
          typeset -g ZSH_HISTORY_RELATIVE_DATES='''

          fzf_history_search() {
            setopt extendedglob

            local script_args=""

            if (( $ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH )); then
              if [[ -n "''${ZSH_HISTORY_RELATIVE_DATES}" ]]; then
                script_args="--relative"
              fi
            fi

            local selected_command
            selected_command=$(${zsh-history-search}/bin/zsh-history-search $script_args)
            local ret=$?

            if [[ -n "$selected_command" ]]; then
              BUFFER="$selected_command"
              zle end-of-line
            fi

            zle reset-prompt
            return $ret
          }

          autoload fzf_history_search
          zle -N fzf_history_search

          bindkey $ZSH_FZF_HISTORY_SEARCH_BIND fzf_history_search
        '';
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
