{ config, lib, pkgs, ... }:

{
  users.users.avo.shell = pkgs.zsh;

  home-manager.users.avo
    .home.packages = with pkgs; [
      direnv
    ];

  home-manager.users.avo
    .home.sessionVariables =
      {
        BLOCK_SIZE  = "\'1";
        COLUMNS     = 100;
        PAGER       = "less";
      } // (
      with config.home-manager.users.avo.xdg; {
        RLWRAP_HOME = "${cacheHome}/rlwrap";
        ZPLUG_HOME  = "${cacheHome}/zplug";
      }) // (import ./private/credentials.nix).env;

  home-manager.users.avo
    .programs.zsh = with config.home-manager.users.avo; rec {
      enable = true;

      dotDir = ".config/zsh";

      enableCompletion = false;
      enableAutosuggestions = true;

      shellAliases = {
        hgrep = "fc -ln 0- | grep";
        j     = "jobs -d | paste - -";
        mkdir = "mkdir -p";
        tree  = "${pkgs.tree}/bin/tree -F --dirsfirst";
      } // {
        browser-history = "${pkgs.avo-scripts}/bin/qutebrowser-history";
      } // {
        e  = "${pkgs.emacs}/bin/emacsclient --socket-name scratchpad --no-wait";
      } // {
        l  = "ls";
        la = "ls -a";
        ls = "ls --group-directories-first --classify --dereference-command-line -v";
      } // {
        gdax = "${pkgs.avo-scripts}/bin/webapp gdax https://www.gdax.com/trade/BTC-USD";
      } // {
        journalctl = "${pkgs.grc}/bin/grc journalctl";
      };

      history = rec {
        size = 99999;
        save = size;
        path = ".cache/zsh_history";
        expireDuplicatesFirst = true;
        share = true;
        extended = true;
      };

      initExtra =
        let
          prompt = builtins.readFile ./prompt.zsh;

          globalAliasesStr =
            let toStr = x: lib.concatStringsSep "\n"
                           (lib.mapAttrsToList (k: v: "alias -g ${k}='${v}'") x);
            in toStr {
              C  = "| wc -l";
              L  = "| less -R";
              H  = "| head";
              T  = "| tail";
              F  = "| ${pkgs.fzf}/bin/fzf | xargs";
              FE = "| ${pkgs.fzf}/bin/fzf | ${pkgs.parallel}/bin/parallel -X --tty $EDITOR";
            };

          functions = {
            "diff" = ''${pkgs.wdiff}/bin/wdiff -n $@ | ${pkgs.colordiff}/bin/colordiff'';
            "open" = ''setsid ${pkgs.xdg_utils}/bin/xdg-open "$*" &>/dev/null'';
            "+x"   = ''chmod +x "$*"'';
            "vi"   = ''grep acme /proc/$PPID/cmdline && command vim -c 'colorscheme acme' $@ || command vim $@'';
          };

          cdAliases = ''
            alias ..='cd ..'
            alias ...='cd .. && cd ..';
            alias ....='cd .. && cd .. && cd ..'
          '';

          direnv = ''
            eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
          '';

          completion = ''
            zstyle ':completion:*' menu select
            zstyle ':completion:*' rehash true
          '';

          plugins = ''
            source ${xdg.cacheHome}/zplug/init.zsh

            zplug 'willghatch/zsh-hooks'; zplug load
            zplug '~/proj/zsh-vim-mode', from:local
            zplug 'zdharma/fast-syntax-highlighting'
            zplug 'hlissner/zsh-autopair', defer:2
            zplug 'chisui/zsh-nix-shell'

            zplug load
          '';
        in lib.concatStringsSep "\n" [
          ''
            setopt HIST_IGNORE_SPACE
            setopt HIST_REDUCE_BLANKS

            setopt EXTENDED_GLOB
            setopt CASE_GLOB
            setopt GLOB_COMPLETE

            setopt INTERACTIVE_COMMENTS

            if [[ $TERM != eterm-color && $TERM != dumb ]]; then
              preexec() { print -Pn "\e]0;$1\a" }
            fi
          ''
          cdAliases
          globalAliasesStr
          (lib.concatStringsSep "\n"
            (lib.mapAttrsToList (name: body:
                              ''
                                ${name}() {
                                  ${body}
                                }
                              '') functions))
          completion
          plugins
          prompt
          direnv
       ];
    };
}
