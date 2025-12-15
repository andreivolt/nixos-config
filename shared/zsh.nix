{pkgs, ...}: let
  zsh-history-search = pkgs.callPackage ../pkgs/zsh-history-search {};
  preview = pkgs.writeShellApplication {
    name = "preview";
    runtimeInputs = with pkgs; [file bat mediainfo];
    text = ''
      file="$1"
      file_type=$(file -b --mime "$file")

      if echo "$file_type" | grep -q "text"; then
          bat --color=always "$file"
      elif echo "$file_type" | grep -q "application/octet-stream"; then
          mediainfo "$file" 2>/dev/null || echo "Cannot preview binary file"
      else
          mediainfo "$file" 2>/dev/null || echo "Cannot preview file"
      fi
    '';
  };
in {
  home-manager.sharedModules = [
    ({config, lib, pkgs, ...}: {
      xdg.enable = true;

      home.sessionVariables = let
        isAsahi = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
        browser =
          if isAsahi then "chromium"
          else if pkgs.stdenv.isDarwin then "google-chrome"
          else "google-chrome-stable";
      in {
        BROWSER = browser;
        DELTA_PAGER = "less";
        DENO_NO_UPDATE_CHECK = "1";
        EDITOR = "nvim";
        TERMINAL = "kitty --single-instance";
        LESS = "--RAW-CONTROL-CHARS --ignore-case --no-init --quit-if-one-screen --use-color --color=Sky --color=Er --color=d+c --color=u+g --color=PK --mouse --incsearch --wordwrap --prompt=?f%f .?m(%i/%m) .?lt%lt-%lb?L/%L. .?e(END):?pB%pB\\%..";
        LESSUTFCHARDEF = "E000-F8FF:p,F0000-FFFFD:p";
        MANPAGER = "nvim +Man!";
        MANWIDTH = "100";
        PAGER = "nvimpager";
        PYTHONDONTWRITEBYTECODE = "1";
        PYTHONWARNINGS = "ignore";
        UV_TOOL_BIN_DIR = "~/.local/bin";
        PKG_CONFIG_PATH = "$HOME/.nix-profile/lib/pkgconfig:/run/current-system/sw/lib/pkgconfig:\${PKG_CONFIG_PATH:-}";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        SHELL_SESSIONS_DISABLE = "1";
        HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
        HOMEBREW_PREFIX = "/opt/homebrew";
        HOMEBREW_REPOSITORY = "/opt/homebrew";
        INFOPATH = "/opt/homebrew/share/info\${INFOPATH:+:$INFOPATH}";
        MANPATH = "/opt/homebrew/share/man\${MANPATH:+:$MANPATH}:";
        LIBRARY_PATH = "/opt/homebrew/opt/libiconv/lib\${LIBRARY_PATH:+:$LIBRARY_PATH}";
      };

      home.sessionPath = [
        "$HOME/go/bin"
        "$HOME/.npm/bin"
        "$HOME/.cargo/bin"
        "$HOME/.cache/.bun/bin"
        "$HOME/.local/bin"
        "$HOME/bin"
      ] ++ lib.optionals pkgs.stdenv.isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
      ];

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

        shellAliases = let
          isAsahi = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
          browser = if isAsahi then "chromium" else "chrome";
        in {
          "+x" = "chmod +x";
          cdt = "cd $(mktemp -d)";
          diff = "diff --color";
          edir = "edir -r";
          eza = "eza --icons always";
          gc = "git clone --depth 1";
          gron = "fastgron";
          http = "xh";
          jq = "gojq";
          l = "ls -1";
          la = "ls -a";
          ll = "ls -l --classify=auto --git";
          lla = "ll -a";
          ls = "eza --group-directories-first";
          mpv = "mpv --ytdl-raw-options=cookies-from-browser=${browser}";
          path = ''printf "%s\n" $path'';
          rg = "rg --smart-case --colors match:bg:yellow --colors match:fg:black";
          rm = "rm --verbose";
          scrcpy = "scrcpy --render-driver opengl";
          vi = "nvim";
          yt-dlp = "yt-dlp --cookies-from-browser ${browser}";
        } // lib.optionalAttrs pkgs.stdenv.isLinux {
          copy = "wl-copy";
          open = "xdg-open";
          paste = "wl-paste";
        } // lib.optionalAttrs pkgs.stdenv.isDarwin {
          copy = "pbcopy";
          paste = "pbpaste";
          tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
        };

        shellGlobalAliases = {
          C = "| wc -l";
          G = "| rg";
          H = "| head";
          L = "| $PAGER";
          N = "&> /dev/null";
          NE = "2> /dev/null";
          X = "| xargs";
        };

        profileExtra = ''
          # conditionals that need shell evaluation
          [[ -f ~/.local/ca-certificates/combined-ca-bundle.pem ]] && export CURL_CA_BUNDLE=~/.local/ca-certificates/combined-ca-bundle.pem
        '';

        initContent = ''
          source ~/.config/env 2>/dev/null || true
          export GPG_TTY="$(tty)"
          READNULLCMD=$PAGER

          # terminal title
          precmd() { print -Pn "\e]0;%~\a" }
          preexec() { print -Pn "\e]0;$1\a" }

          # cat function: use bat for interactive, real cat for pipes
          cat() {
            if [[ -t 1 ]]; then
              bat "$@"
            else
              command cat "$@"
            fi
          }

          # ssh function: use kitten for interactive, real ssh for non-interactive
          ${lib.optionalString config.programs.kitty.enable ''
          ssh() {
            if [[ -t 0 ]]; then
              kitten ssh "$@"
            else
              command ssh "$@"
            fi
          }
          ''}

          source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh

          # platform-specific config
          ${lib.optionalString pkgs.stdenv.isDarwin "source ~/.config/zsh/darwin.zsh"}

          # zsh config files
          source ~/.config/zsh/vi.zsh
          zsh-defer source ~/.config/zsh/completion.zsh
          source ~/.config/zsh/prompt.zsh
          [[ -n "$TMUX" ]] && zsh-defer source ~/.config/zsh/tmux.zsh
          zsh-defer source ~/.config/zsh/fzf.zsh
          zsh-defer source ~/.config/zsh/history-search.zsh

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
          source ~/.config/zsh/p10k.zsh
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
        "zsh/preview".source = "${preview}/bin/preview";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        "zsh/darwin.zsh".source = ./zsh/darwin.zsh;
      };

      home.activation.createZshDirs = ''
        mkdir -p ~/.cache/zsh
        mkdir -p ~/.local/share/zsh
        mkdir -p ~/.local/state/zsh
      '';
    })
  ];
}
