{ pkgs, config, lib, ... }:

{
  users.users.avo.shell = pkgs.zsh;

  home-manager.users.avo.programs.zsh = with config.home-manager.users.avo; rec {
    enable = true;

    dotDir = ".config/zsh";

    enableCompletion = false;
    enableAutosuggestions = true;

    shellAliases = {
      R               = "ramda";
      bitcoin         = "bitcoin -datadir ${xdg.dataHome}/bitcoin/bitcoin.conf";
      browser-history = "qutebrowser-history";
      e               = "${pkgs.emacs}/bin/emacsclient -s scratchpad --no-wait";
      fzf             = "${pkgs.fzf}/bin/fzf --color bw";
      gc              = "${pkgs.gitAndTools.hub}/bin/hub clone";
      git             = "${pkgs.gitAndTools.hub}/bin/hub";
      gr              = "cd $(${pkgs.git}/bin/git root)";
      grep            = "grep --color=auto";
      j               = "jobs -d | paste - -";
      l               = "ls";
      la              = "ls -a";
      ls              = "ls --group-directories-first --classify --dereference-command-line -v";
      mkdir           = "mkdir -p";
      rg              = "${pkgs.ripgrep}/bin/rg --smart-case --colors match:bg:yellow --colors match:fg:black";
      tree            = "${pkgs.tree}/bin/tree -F --dirsfirst";
      vi              = "${pkgs.neovim}/bin/nvim";
      vpnoff          = "sudo systemctl stop openvpn-us";
      vpnon           = "sudo systemctl start openvpn-us";
      mitmproxy       = "mitmproxy --conf ${xdg.configHome}/mitmproxy/config.yaml";
    } // {
      gdax            = "webapp https://www.gdax.com/trade/BTC-USD";
      pandora         = "webapp https://www.pandora.com/my-music";
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

     profileExtra = "source ${xdg.configHome}/private.env";
  };
}
