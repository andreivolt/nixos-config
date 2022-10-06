{ pkgs, config, ... }: {
  home.sessionVariables.EDITOR = "nvim";

  # home.activation = {
  #   aliasApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   ln -sfn $genProfilePath/home-path/Applications "$HOME/Applications/Home Manager Applications"
  #   '';
  # };

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;

  # programs.zsh.enableCompletion = false;

  # programs.zsh.enableInteractiveComments = true; # TODO not on home-manager

  # programs.zsh.enableSyntaxHighlighting = true;

  programs.zsh.defaultKeymap = "viins";

  programs.zsh.enable = true; # TODO
  # programs.zsh.enableSyntaxHighlighting = true;

  # edit without rebuilding
  programs.zsh.initExtra = ''
    # trigger completion on globbing
    setopt glob_complete

    # remove extraneous spaces from saved commands
    setopt hist_reduce_blanks

    # show menu when completing
    zstyle ':completion:*' menu select

    # automatically update PATH
    zstyle ':completion:*' rehash true

    # automatically add directories to the directory stack
    setopt auto_pushd

    # # set terminal title
    # source ${./zsh/terminal-title.zsh}

    # case-insensitive completion
    zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
    # autoload -Uz compinit && compinit

    source ~/.zshrc.extra.zsh;
  '';

  programs.zsh.plugins = with pkgs; [
    {
      name = "autopair";
      file = "autopair.zsh";
      src = fetchFromGitHub {
        owner = "hlissner";
        repo = "zsh-autopair";
        rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1";
        sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
      };
    }
    {
      name = "zsh-nix-shell";
      file = "nix-shell.plugin.zsh";
      src = fetchFromGitHub {
        owner = "chisui";
        repo = "zsh-nix-shell";
        rev = "v0.2.0";
        sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
      };
    }
  ];

  programs.zsh.history = rec {
    size = 99999;
    save = size;
    share = true;
    ignoreSpace = true;
    ignoreDups = true;
    extended = true;
    # path = ".cache/zsh_history";
  };

  programs.zsh.shellAliases = import ../aliases.nix;

  programs.zsh.shellGlobalAliases = import ./zsh-global-aliases.nix;
}
