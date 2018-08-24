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
        l  = "ls";
        la = "ls -a";
        ls = "ls --group-directories-first --classify --dereference-command-line -v";
        mkdir = "mkdir -p";
        tree  = "${pkgs.tree}/bin/tree -F --dirsfirst";
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
          globalAliasesStr =
            let toStr = x: lib.concatStringsSep "\n"
                           (lib.mapAttrsToList (k: v: "alias -g ${k}='${v}'") x);
            in toStr {
              C = "| wc -l";
              L = "| less -R";
              H = "| head";
              T = "| tail";
              F = "| ${pkgs.fzf}/bin/fzf | xargs";
              FE = "| ${pkgs.fzf}/bin/fzf | ${pkgs.parallel}/bin/parallel -X --tty $EDITOR";
            };

          functions = {
            "+x" = ''chmod +x "$*"'';
            "diff" = ''${pkgs.wdiff}/bin/wdiff -n $@ | ${pkgs.colordiff}/bin/colordiff'';
            "open" = ''setsid ${pkgs.xdg_utils}/bin/xdg-open "$*" &>/dev/null'';
            "vi" = ''grep acme /proc/$PPID/cmdline && command vim -c 'colorscheme acme' $@ || command vim $@'';
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

          prompt = ''
            prompt_precmd() {
              rehash

              local jobs
              local prompt_jobs
              unset jobs
              for a (''${(k)jobstates}) {
                j=$jobstates[$a];i=\'''''${''${(@s,:,)j}[2]}'
                jobs+=($a''${i//[^+-]/})
              }

              prompt_jobs=""
              [[ -n $jobs ]] && prompt_jobs="%F{black}["''${(j:,:)jobs}"]%f "

              setopt promptsubst
              PROMPT="%K{white} $prompt_jobs%F{black}%~ $ %f%k "
            }

            prompt_opts=(cr percent sp subst)

            add-zsh-hook precmd prompt_precmd
          '';
        in lib.concatStringsSep "\n" [
          ''
            setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
            setopt EXTENDED_GLOB CASE_GLOB GLOB_COMPLETE
            setopt INTERACTIVE_COMMENTS

            preexec() { print -Pn "\e]0;$1\a" }
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
