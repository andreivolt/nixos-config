{ config, lib, pkgs, ... }:

{
  users.users.avo.shell = pkgs.zsh;

  environment.variables.BLOCK_SIZE = "\'1";

  environment.variables.ZPLUG_HOME = "$HOME/.cache/zplug";

  environment.systemPackages = with pkgs; [
    direnv
    nix-zsh-completions
  ];

  programs.zsh = {
    enable = true;

    enableCompletion = true;

    autosuggestions.enable = true;

    shellAliases = {};

    interactiveShellInit = let
      aliases = let
        toStr = x:
          lib.concatStringsSep "\n"
            (lib.mapAttrsToList (k: v: "alias ${k}='${v}'") x);
      in toStr {
        hgrep = "fc -ln 0- | grep";
        l = "ls";
        la = "ls -a";
        ls = "ls --group-directories-first --classify --dereference-command-line -v";
        mkdir = "mkdir -p";
        tree = "${pkgs.tree}/bin/tree -F --dirsfirst";
      };

      history = ''
        HISTSIZE=99999
        SAVEHIST=$HISTSIZE
        HISTFILE=~/.cache/zsh_history
        setopt \
          extended_history \
          hist_ignore_all_dups \
          hist_ignore_space \
          hist_reduce_blanks \
          share_history
      '';

      globalAliases = let
        toStr = x:
          lib.concatStringsSep "\n"
            (lib.mapAttrsToList (k: v: "alias -g ${k}='${v}'") x);
      in toStr {
        C = "| wc -l";
        L = "| less";
        H = "| head";
        T = "| tail";
        F = "| ${pkgs.fzf}/bin/fzf | xargs";
        FE = "| ${pkgs.fzf}/bin/fzf | ${pkgs.parallel}/bin/parallel -X --tty $EDITOR";
      };

      functions = let
        toStr = x:
          lib.concatStringsSep "\n"
           (lib.mapAttrsToList
             (name: body: ''
               ${name}() {
                 ${body}
               }
             '')
             x);
      in toStr {
        "+x" = ''chmod +x "$*"'';
        "diff" = ''${pkgs.wdiff}/bin/wdiff -n $@ | ${pkgs.colordiff}/bin/colordiff'';
        "each" = ''xargs -i -n1 $1 "{}"'';
        "open" = ''setsid ${pkgs.xdg_utils}/bin/xdg-open "$*" &>/dev/null'';
      };

      cdAliases = ''
        alias ..='cd ..'
        alias ...='cd .. && cd ..';
        alias ....='cd .. && cd .. && cd ..'
      '';

      direnv = ''eval "$(${pkgs.direnv}/bin/direnv hook zsh)"'';

      completion = ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' rehash true
      '';

      fzfIntegration = ''
        source ${pkgs.fzf}/share/fzf/completion.zsh
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      '';

      plugins = ''
        source ~/.cache/zplug/init.zsh

        zplug 'willghatch/zsh-hooks'; zplug load
        zplug '/etc/nixos/programs/zsh/zsh-vim-mode', from:local
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
          [[ -n $jobs ]] && prompt_jobs=" ["''${(j:,:)jobs}"] "

          setopt promptsubst

          PROMPT="%B%F{green}➤%b%f "
          RPROMPT="%F{8}$prompt_jobs%~%f"
        }

        prompt_opts=(cr percent sp subst)

        add-zsh-hook precmd prompt_precmd
      '';

      globbing = ''
        setopt \
          case_glob \
          extended_glob \
          glob_complete
      '';
    in lib.concatStringsSep "\n" [
      ''
        zle_highlight=(isearch:underline,fg=yellow)
      ''
      aliases
      cdAliases
      completion
      direnv
      functions
      globalAliases
      globbing
      history
      plugins
      prompt
      fzfIntegration
    ];
  };
}
