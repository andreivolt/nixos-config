{ pkgs, config, lib, ... }:

{
  users.users.avo.shell = pkgs.zsh;

  home-manager.users.avo
    .home.packages = with pkgs; [
      # antigen-hs
      # autojump
      # https:++github.com/rupa/z
      # https://github.com/b4b4r07/enhancd
      # https://github.com/zplug/zplug
      # zsh-powerlevel9k
      direnv
    ];

  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo.xdg; {
      BLOCK_SIZE  = "\'1";
      COLUMNS     = 100;
      PAGER       = ''
                      less \
                      --quit-if-one-screen \
                      --no-init \
                      --RAW-CONTROL-CHARS'';
      RLWRAP_HOME = "${cacheHome}/rlwrap";
      ZPLUG_HOME  = "${cacheHome}/zplug";
    } // (import ./credentials.nix).env;


  environment.pathsToLink = [ "/share/zsh" ];

  home-manager.users.avo
    .programs.zsh = with config.home-manager.users.avo; rec {
      enable = true;

      dotDir = ".config/zsh";

      enableCompletion = false;
      enableAutosuggestions = true;

      shellAliases = {
        fzf             = "${pkgs.fzf}/bin/fzf --color bw";
        hgrep           = "fc -ln 0- | grep";
        j               = "jobs -d | paste - -";
        mkdir           = "mkdir -p";
        tree            = "${pkgs.tree}/bin/tree -F --dirsfirst";
      } // {
        R = "ramda";
      } // {
        browser-history = "${pkgs.avo-scripts}/bin/qutebrowser-history";
      } // {
        e               = "${pkgs.emacs}/bin/emacsclient --socket-name scratchpad --no-wait";
        vi              = "vim";
      } // {
        l               = "ls";
        la              = "ls -a";
        ls              = "ls --group-directories-first --classify --dereference-command-line -v";
      } // {
        gdax            = "${pkgs.avo-scripts}/bin/webapp gdax https://www.gdax.com/trade/BTC-USD";
      };

      history = rec {
        size = 99999;
        save = size;
        path = ".cache/zsh_history";
        ignoreDups = true;
        share = true;
        extended = true;
        ignoreSpace = true;
        reduceBlanks = true;
      };

      setTerminalTitle = true;

      glob = {
        extended = true;
        case = false;
        complete = true;
      };

      enableInteractiveComments = true;

      enableDirenv = true;

      initExtra =
        let
          globalAliasesStr =
            let toStr = x: lib.concatStringsSep "\n"
                           (lib.mapAttrsToList (k: v: "alias -g ${k}='${v}'") x);
            in toStr {
              C  = "| wc -l";
              L  = "| less -R";
              H  = "| head";
              T  = "| tail";
              Y  = "| ${pkgs.xsel}/bin/xsel -b";
              N  = "2>/dev/null";
              F  = "| ${pkgs.fzf}/bin/fzf | xargs";
              FE = "| ${pkgs.fzf}/bin/fzf | ${pkgs.parallel}/bin/parallel -X --tty $EDITOR";
            };

          autoRlwrap = ''
            #zplug 'andreivolt/zsh-auto-rlwrap'
            #bindkey -M viins '^x' insert-rlwrap
            #bindkey -M vicmd '^x' insert-rlwrap
          '';

          functions = ''
            diff() { ${pkgs.wdiff}/bin/wdiff -n $@ | ${pkgs.colordiff}/bin/colordiff }
            open() { setsid xdg-open "$*" &>/dev/null }
            +x() { chmod +x "$*" }
          '';

          cdAliases = ''
            alias ..='cd ..'
            alias ...='cd .. && cd ..';
            alias ....='cd .. && cd .. && cd ..'
          '';

          completion = ''
            zstyle ':completion:*' menu select
            zstyle ':completion:*' rehash true
          '';

          plugins = ''
            source ${xdg.cacheHome}/zplug/init.zsh
            zplug 'willghatch/zsh-hooks'; zplug load
            zplug 'andreivolt/zsh-prompt-lean'
            zplug 'andreivolt/zsh-vim-mode', defer:2; zplug load
            zplug 'zdharma/fast-syntax-highlighting'
            zplug 'hlissner/zsh-autopair', defer:2
            zplug 'chisui/zsh-nix-shell'
            zplug 'chrismwendt/auto-nix-shell'
            zplug load
          '';
        in ''
          ${cdAliases}
          ${globalAliasesStr}
          ${autoRlwrap}
          ${functions}
          ${completion}
          ${plugins}
       '';
    };
}
