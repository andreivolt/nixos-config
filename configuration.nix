{ config, lib, pkgs, ... }:

with lib;

let
  aliases = {
    e = "setsid &>/dev/null emacsclient --create-frame";
    hgrep = "fc -ln 0- | grep";
    l = "ls";
    la = "ls -a";
    ll = "ls -l";
    ls = "ls --no-group --group-directories-first --classify --dereference-command-line -v";
    mkdir = "mkdir -p";
    tree = "${pkgs.tree}/bin/tree -F --dirsfirst";
    vi = "vim";
  };

in {
  imports = [
    # ./modules.d/wayland.nix
    ./hardware-configuration.nix
    ./modules.d/android.nix
    ./modules.d/audio.nix
    ./modules.d/automount-removable-devices.nix
    ./modules.d/block-ads.nix
    ./modules.d/chromecast.nix
    ./modules.d/clojure.nix
    ./modules.d/cloudflare-dns.nix
    ./modules.d/direnv.nix
    ./modules.d/docker.nix
    ./modules.d/emacs-edit-server.nix
    ./modules.d/email.nix
    ./modules.d/fonts.nix
    ./modules.d/git.nix
    ./modules.d/http-reverse-proxy.nix
    ./modules.d/insync.nix
    ./modules.d/isync.nix
    ./modules.d/libvirt.nix
    ./modules.d/map-caps-lock-to-ctrl.nix
    ./modules.d/map-test-tld-to-localhost.nix
    ./modules.d/mdns.nix
    ./modules.d/node.nix
    ./modules.d/notifications.nix
    ./modules.d/nvidia-shield-mount.nix
    ./modules.d/nvidia.nix
    ./modules.d/printing.nix
    ./modules.d/remotectl.nix
    ./modules.d/sshd.nix
    ./modules.d/tmux.nix
    ./modules.d/todos.nix
    ./modules.d/tor.nix
    ./modules.d/touchpad.nix
    ./modules.d/vi-readline.nix
    ./modules.d/wifi.nix
    ./modules.d/x11.nix
    ./modules.d/zsh-vi.nix
    ./modules.d/xmonad
  ];

  boot.kernel.sysctl."vm.swappiness" = 10; # avoid swapping
  boot.kernel.sysctl."vm.vfs_cache_pressure" = 50; # avoid reclaiming memory from file caches

  boot.kernel.sysctl."kernel.core_pattern" = "|/run/current-system/sw/bin/false"; # disable core dumps

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (import ./packages)
    (import ./wrapped)
  ];

  nix = {
    buildCores = 0;
    gc.automatic = true; optimise.automatic = true;
    useSandbox = false;
  };

  hardware.bluetooth.enable = true;

  hardware.opengl.enable = true;

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  networking.hostName = builtins.getEnv "HOSTNAME";

  services.emacs = {
    enable = true;
    package = pkgs.avo.emacs;
  };

  # default apps
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/pdf=org.pwmt.zathura.desktop'';
  environment.etc."xdg/user-dirs.defaults".text = "XDG_DOWNLOAD_DIR=$HOME/tmp; XDG_DESKTOP_DIR=$HOME/tmp";
  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
  environment.variables.BROWSER = "browser";
  environment.variables.EDITOR = "vim";
  environment.variables.PAGER = "less";

  environment.systemPackages = with pkgs; with wrapped; [
    # libreoffice-fresh
    # mitmproxy
    (hunspellWithDicts (with hunspellDicts; [
      en-us
      fr-moderne
      avo.hunspell-ro
    ]))
    acpi
    aria
    awscli
    bat
    binutils
    bitcoin
    dnsutils
    docker_compose
    dtrx
    file
    flameshot
    fzf
    git-hub
    gnugrep
    gnupg
    google-cloud-sdk
    graphicsmagick
    httpie
    jq
    jre
    lastpass-cli
    less
    lsof
    moreutils
    mpv
    msmtp
    neomutt
    neovim
    nethogs
    nmap
    notmuch
    openssh
    openssl
    parallel
    psmisc
    pup
    recode
    redshift
    ripgrep
    rlwrap
    rmlint
    setroot
    slack
    socat
    strace
    sxiv
    telnet
    texlive.combined.scheme-full
    tree
    urlwatch
    w3m
    weechat
    wmctrl
    xclip
    xdotool
    xfce.thunar
    xsel
    xurls
    youtube-dl
    zathura
  ] ++
  (with avo; [
    adb-tcpip
    blink-diff
    browser
    center-window
    chmodx
    colorpicker
    diff
    display-off
    emacs
    emacs-clojure
    emacs-irc
    emacs-notmuch
    emacs-toggle-theme
    fill-pdf-form
    gmail
    google-search
    google-tts
    guesslang
    launcher
    macos
    macos-nixos-rebuild
    md2pdf
    nightmode
    npm-run
    open
    phonecall
    private-browser
    pushbullet
    pushover
    rebuild
    set-scratchpad
    sms
    termdo
    terminal
    todos
    todos-lib
    upgrade
    volumectl
    webapp
    whattimeisit
    windows
    zprint
  ]);
  # ++ (
  #   let mkWebapp = name: url: nameValuePair name (pkgs.writeShellScriptBin name "\${webapp}/bin/webapp '${url}'"); in mapAttrs mkWebapp {
  #     gmail = "https://mail.google.com/mail/u/1";
  #     youtube-music = "https://music.youtube.com";
  #   }));

  # shell
  environment.variables.ZDOTDIR = "/etc";
  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.shellAliases = aliases;
  programs.zsh.promptInit = let
    nix-shell-plugin = pkgs.fetchFromGitHub {
      owner = "chisui"; repo = "zsh-nix-shell";
      rev = "03a1487655c96a17c00e8c81efdd8555829715f8"; sha256 = "1avnmkjh0zh6wmm87njprna1zy4fb7cpzcp8q7y03nw3aq22q4ms";
    };
  in ''
    source ${nix-shell-plugin}/nix-shell.plugin.zsh

    autoload -Uz vcs_info
    zstyle ':vcs_info:git*' formats "%F{black}%K{green} %r %k%K{8} %b %k%f%a"

    prompt_precmd() {
      rehash

      vcs_info

      local jobs; unset jobs
      local prompt_jobs
      for a (''${(k)jobstates}) {
        j=$jobstates[$a];i=\'''''${''${(@s,:,)j}[2]}'
        jobs+=($a''${i//[^+-]/})
      }
      prompt_jobs=""
      [[ -n $jobs ]] && prompt_jobs="["''${(j:,:)jobs}"]"
      # (jobs | sed -r 's/..suspended//; s/ +/ /; s/^/%K{blue}/; s/$/%k/' | tr '\n' ' ')

      [[ -n $IN_NIX_SHELL ]] && local nix_shell_indicator='%K{yellow}%F{black} NIX %f%k'
      [[ -n $DIRENV_DIR ]] && local direnv_indicator='%K{magenta}%F{black} ENV %f%k'

      setopt promptsubst
      PROMPT="
%(?.%F{green}.%F{red})╭─%f$direnv_indicator$nix_shell_indicator''${vcs_info_msg_0_}%f%F{8} %~%f
%(?.%F{green}.%F{red})╰─%f$prompt_jobs%f%B%F{blue}%b%f "
    }

    prompt_opts=(cr percent sp subst)
    add-zsh-hook precmd prompt_precmd
  '';
  programs.zsh.interactiveShellInit = let
    autopair = let _ = pkgs.fetchFromGitHub {
      owner = "hlissner"; repo = "zsh-autopair";
      rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1"; sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
    }; in "source ${_}/autopair.zsh";

    completion = ''
      zstyle ':completion:*' menu select
      zstyle ':completion:*' rehash true'';

    fast-syntax-highlighting = let _ = pkgs.fetchFromGitHub {
      owner = "zdharma"; repo = "fast-syntax-highlighting";
      rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e"; sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
    }; in "source ${_}/fast-syntax-highlighting.plugin.zsh";

    fzf = ''
      source ${pkgs.wrapped.fzf}/share/fzf/completion.zsh
      source ${pkgs.wrapped.fzf}/share/fzf/key-bindings.zsh'';

    global-aliases = let toStr = attrs: concatStringsSep "\n" (mapAttrsToList (k: v: "alias -g ${k}='${v}'") attrs); in toStr {
      C = "| wc -l";
      F = "$(fzf)";
      H = "| head";
      L = "| less";
      T = "| tail"; };

    globbing = ''
      setopt \
        case_glob \
        extended_glob \
        glob_complete'';

    history = ''
      HISTSIZE=99999 SAVEHIST=$HISTSIZE
      HISTFILE=~/.cache/zsh_history
      setopt \
        extended_history \
        hist_ignore_all_dups \
        hist_ignore_space \
        hist_reduce_blanks \
        share_history'';

    nix-shell-auto = ''
      in-nix-project() {
        if [[ -z $1 ]]; then
          in-nix-project $PWD
        else
          [[ -f $1/shell.nix ]] || {
            if [[ $1 = / ]]; then
              false
            else
              in-nix-project $(dirname $1)
            fi
          }
        fi
      }

      add-zsh-hook -Uz chpwd (){ in-nix-project && nix-shell || [[ -n $IN_NIX_SHELL ]] && exit }'';

    terminal-title = ''
      precmd() { print -Pn "\e]0;TTY\a" }
      preexec() { print -Pn "\e]0;$1\a" }'';
  in concatStringsSep "\n" [
    "setopt autocd"
    autopair
    completion
    fast-syntax-highlighting
    global-aliases
    globbing
    history
    # nix-shell-auto
    terminal-title
    fzf
  ];
}
