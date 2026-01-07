{pkgs, ...}: let
  zsh-history-search = pkgs.callPackage ../../pkgs/zsh-history-search {};
  preview = pkgs.writeShellApplication {
    name = "preview";
    runtimeInputs = with pkgs; [file bat mediainfo];
    text = ''
      file="$1"
      file_type=$(file -b --mime "$file")

      if echo "$file_type" | grep -q "text"; then
          bat --color=always --style=plain "$file"
      elif echo "$file_type" | grep -q "application/octet-stream"; then
          mediainfo "$file" 2>/dev/null || echo "Cannot preview binary file"
      else
          mediainfo "$file" 2>/dev/null || echo "Cannot preview file"
      fi
    '';
  };
in {
  home-manager.sharedModules = [
    ./environment.nix
    ./aliases.nix
    ({config, lib, pkgs, ...}: {
      xdg.enable = true;

      programs.zsh = {
        enable = true;
        enableCompletion = false; # handled in completion.zsh

        autocd = true;
        history = {
          size = 999999;
          save = 999999;
          path = "${config.xdg.stateHome}/zsh/history";
          extended = true;
          ignoreDups = true;
          ignoreSpace = true;
          share = true;
        };

        setOptions = [
          "hist_fcntl_lock"
          "hist_reduce_blanks"
          "auto_pushd"
          "extended_glob"
          "interactive_comments"
          "null_glob"
          "numeric_glob_sort"
        ];

        profileExtra = ''
          # conditionals that need shell evaluation
          [[ -f ~/.local/ca-certificates/combined-ca-bundle.pem ]] && export CURL_CA_BUNDLE=~/.local/ca-certificates/combined-ca-bundle.pem
        '';

        initContent = ''
          export GPG_TTY="$(tty)"
          READNULLCMD=$PAGER

          # terminal title
          precmd() { print -Pn "\e]0;zsh (%~)\a" }
          preexec() { print -Pn "\e]0;$1 (%~)\a" }

          # cat function: use bat for interactive, real cat for pipes
          cat() {
            if [[ -t 1 ]]; then
              bat "$@"
            else
              command cat "$@"
            fi
          }

          # ssh function: use kitten for interactive kitty sessions
          ${lib.optionalString config.programs.kitty.enable ''
          ssh() {
            if [[ -t 0 && -n "$KITTY_WINDOW_ID" ]]; then
              kitten ssh "$@"
            else
              command ssh "$@"
            fi
          }
          ''}

          ${lib.optionalString pkgs.stdenv.isLinux ''
          open() { setsid -f xdg-open "$@" >/dev/null 2>&1; }
          ''}

          source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh

          # platform-specific config
          ${lib.optionalString pkgs.stdenv.isDarwin "source ${./darwin.zsh}"}

          # zsh config files
          source ${./vi.zsh}
          source ${./completion.zsh}
          source ~/.config/zsh/prompt.zsh
          [[ -n "$TMUX" ]] && zsh-defer source ${./tmux.zsh}
          zsh-defer source ${./fzf.zsh}
          zsh-defer source ${./history-search.zsh}

          bindkey ' ' magic-space # history expansion

          zsh-defer source ~/.config/zsh/autopair.zsh
          zsh-defer source ~/.config/zsh/autosuggestions.zsh
          zsh-defer source ~/.config/zsh/nix-shell.zsh
          zsh-defer source ~/.config/zsh/syntax-highlighting.zsh
        '';
      };

      xdg.configFile = {
        "zsh/prompt.zsh".text = ''
          [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]] && \
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          source ${./p10k.zsh}
        '';
        "zsh/autopair.zsh".text = ''
          source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
          autopair-init
        '';
        "zsh/autosuggestions.zsh".text = ''
          export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
          source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        '';
        "zsh/nix-shell.zsh".text = ''
          source ${pkgs.zsh-nix-shell}/share/zsh/plugins/zsh-nix-shell/nix-shell.plugin.zsh
        '';
        "zsh/syntax-highlighting.zsh".text = ''
          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
        '';
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
        "zsh/preview".source = "${preview}/bin/preview";
      };

      home.activation.createZshDirs = ''
        mkdir -p ~/.cache/zsh
        mkdir -p ~/.local/share/zsh
        mkdir -p ~/.local/state/zsh
      '';
    })
  ];
}
