{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
    ./modules.d/clojure.nix
    ./modules.d/insync-home-mounts.nix
    ./modules.d/node.nix
    ./modules.d/nvidia-shield-mount.nix
    ./modules.d/todos.nix
    ./modules.d/touchpad.nix
    ./xmonad
  ];

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 100000; # increase inotify watches
  boot.kernel.sysctl."vm.swappiness" = 10; # avoid swapping
  boot.kernel.sysctl."vm.vfs_cache_pressure" = 50; # avoid reclaiming memory from file caches
  boot.kernel.sysctl."kernel.core_pattern" = "|/run/current-system/sw/bin/false"; # disable core dumps

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ./packages)
    (import ./wrapped)];

  nix = {
    buildCores = 0;
    gc.automatic = true; optimise.automatic = true;
    useSandbox = false; };

  # audio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.extraConfig = "load-module module-alsa-sink device=hw:1,9"; # output audio to HDMI
  hardware.bluetooth.enable = true;

  # keyboard
  services.xserver.layout = "fr";

  # map Caps Lock to Ctrl
  services.xserver.xkbOptions = "ctrl:nocaps";
  i18n.consoleUseXkbConfig = true;

  # hardware video acceleration
  hardware.opengl.extraPackages = [ pkgs.vaapiVdpau ];
  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  hardware.opengl.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  # xorg
  services.xserver.enable = true;
  services.xserver.displayManager.auto = { enable = true; user = "avo"; };
  services.xserver.displayManager.sessionCommands = "xrdb -merge /etc/X11/Xresources; redshift -O 4000";
  services.xserver.desktopManager.xterm.enable = false;
  # environment.etc."X11/Xresources".text = ''
  #   Xft.dpi: 192
  # '';

  # fix Nvidia tearing
  services.xserver.screenSection = ''
    Option "metamodes" "DP-0: nvidia-auto-select +0+0 { ForceCompositionPipeline=On }, DP-2: nvidia-auto-select +0+0 { ForceCompositionPipeline=On, SameAs=DP-0 }"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on" '';

  # compton
  services.compton = {
    enable = true;
    shadow = true; shadowOffsets = [ (-15) (-5) ]; shadowOpacity = "0.7";
    extraOptions = "shadow-radius = 10;"; };

  services.unclutter.enable = true;

  systemd.user.services.notify-osd = {
    wantedBy = [ "graphical-session.target" ]; after = [ "graphical-session-pre.target" ]; partOf = [ "graphical-session.target" ];
    path = [ pkgs.notify-osd ];
    script = "notify-osd"; };

  services.emacs = {
    enable = true;
    package = pkgs.avo.emacs; };

  systemd.user.services.emacs-clojure = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.avo.emacs-clojure ];
    script = "source ${config.system.build.setEnvironment} && emacs-clojure_server";
    serviceConfig.Restart = "always"; };

  systemd.user.services.emacs-edit-server = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.avo.emacs-edit-server ];
    script = "source ${config.system.build.setEnvironment} && emacs-edit-server";
    serviceConfig.Restart = "always"; };

  systemd.user.services.emacs-notmuch = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.avo.emacs-notmuch-server ];
    script = "source ${config.system.build.setEnvironment} && emacs-notmuch-server";
    serviceConfig.Restart = "always"; };

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "adbusers"
      "docker"
      "libvirt"
      "wheel" ]; };
  security.sudo.wheelNeedsPassword = false;

  # readline
  environment.etc."inputrc".text = ''
    set editing-mode vi

    set completion-ignore-case on
    set show-all-if-ambiguous on

    set keymap vi
    C-r: reverse-search-history
    C-f: forward-search-history
    C-l: clear-screen
    v: rlwrap-call-editor'';

  # fonts
  fonts = {
    fontconfig.ultimate = { enable = true; preset = "windowsxp"; };
    fontconfig.defaultFonts = { monospace = [ "Roboto Mono" ]; sansSerif = [ "Proxima Nova" ]; };
    enableCoreFonts= true;
    fonts = with pkgs; [ google-fonts hack-font vistafonts ]; };

  # networking
  networking.hostName = builtins.getEnv "HOSTNAME";

  networking.wireless = {
    enable = true;
    networks = mapAttrs'
      (k: v: nameValuePair k (listToAttrs [ (nameValuePair "psk" v) ]))
      (import /home/avo/lib/credentials.nix).wifi; };

  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  services.dnsmasq.enable = true;
  services.dnsmasq.servers = [ "1.1.1.1" ];
  services.dnsmasq.extraConfig = "address=/test/127.0.0.1";

  services.tor.enable = true;
  services.tor.client = { enable = true; transparentProxy.enable = true; };

  # ad blocking
  networking.extraHosts = builtins.readFile (builtins.fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts);

  # sshd
  services.openssh.enable = true;
  users.users.avo.openssh.authorizedKeys.keys = [ (import /home/avo/lib/credentials.nix).ssh_keys.public ];

  # automount removable devices
  services.devmon.enable = true;

  # printing
  services.printing.enable = true;
  services.printing.clientConf = ''
    <Printer default>
      UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
      MakeModel DCP-L2520DW series
      DeviceURI ipp://192.168.1.15/ipp/print
    </Printer>
  '';
  environment.variables.PRINTER = "default";

  # default apps
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/pdf=org.pwmt.zathura.desktop'';
  environment.etc."xdg/user-dirs.defaults".text = "XDG_DOWNLOAD_DIR=$HOME/tmp; XDG_DESKTOP_DIR=$HOME/tmp";
  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
  environment.variables.BROWSER = "${pkgs.avo.browser}/bin/browser";
  environment.variables.EDITOR = "vim";
  environment.variables.PAGER = "${pkgs.wrapped.less}/bin/less";

  services.offlineimap = { enable = true; package = pkgs.wrapped.offlineimap; };

  environment.systemPackages = with pkgs; with wrapped; [
    (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne avo.hunspell-ro ]))
    (lowPrio moreutils) # prefer GNU parallel
    # xpra
    acpi
    aria
    awscli
    bat
    binutils
    bitcoin
    boot
    cifs-utils
    clojure
    direnv
    dnsutils
    docker_compose
    dtrx
    file
    flameshot
    fzf
    git
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
    libinput-gestures
    libnotify
    # libreoffice-fresh
    lsof
    mitmproxy
    mpv
    msmtp
    neomutt
    neovim
    nethogs
    nmap
    nodejs
    notmuch
    openssh
    openssl
    parallel
    psmisc
    pup
    python3Packages.pip
    recode
    redshift # TODO
    ripgrep
    rlwrap
    setroot # TODO
    slack
    strace
    sxiv
    telnet
    texlive.combined.scheme-full
    tree
    urlwatch
    virt-viewer
    weechat
    wmctrl
    xclip
    xdotool
    xfce.thunar
    xsel
    yarn
    youtube-dl
    xurls
    zathura ]
  ++
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
    emacs-toggle-theme
    fill-pdf-form
    gmail
    google-search
    google-tts
    guesslang
    inbox
    launcher
    macos
    macos-nixos-rebuild
    md2pdf
    nightmode
    npm-run
    open
    pdf2text
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
    zprint ]);
  # ++ (
  #   let mkWebapp = name: url: nameValuePair name (pkgs.writeShellScriptBin name "\${webapp}/bin/webapp '${url}'"); in mapAttrs mkWebapp {
  #     gmail = "https://mail.google.com/mail/u/1";
  #     youtube-music = "https://music.youtube.com";
  #   }));

  programs.adb.enable = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true; };
  systemd.services.docker-nginx-proxy = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.docker ];
    script = ''
      docker rm -f nginx-proxy 2>/dev/null || true
      docker network create nginx-proxy 2>/dev/null || true
      docker run \
        -p 80:80 \
        --name nginx-proxy \
        --network nginx-proxy \
        -v ${pkgs.writeText "_" "proxy_read_timeout 999;"}:/etc/nginx/conf.d/custom.conf:ro \
        -v /etc/nginx/vhost.d \
        -v /var/run/docker.sock:/tmp/docker.sock:ro \
        jwilder/nginx-proxy''; };

  # Insync
  systemd.user.services.insync = {
    after = [ "network.target" ]; wantedBy = [ "default.target" ];
    path = [ pkgs.insync ];
    script = "insync start";
    serviceConfig.Type = "forking";
    serviceConfig.Restart = "always"; };

  # Isync
  systemd.user.services.isync = {
    serviceConfig.Type = "oneshot";
    path = [ pkgs.wrapped.isync ];
    script = "mbsync main"; };
  systemd.user.timers.isync = {
    wantedBy = [ "default.target" ];
    timerConfig = { Unit = "isync.service"; OnCalendar = "*:*:0/30"; }; };

  # libvirt
  virtualisation.libvirtd.enable = true;
  environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";
  networking.bridges.br0.interfaces = [ "enp0s31f6" ];
  networking.firewall.trustedInterfaces = [ "br0" ];

  # # Clojure
  # environment.variables.CLJ_CONFIG = let _ = ''
  #   {:aliases {:find-deps {:extra-deps
  #                           {find-deps
  #                              {:git/url "https://github.com/hagmonk/find-deps",
  #                               :sha "6fc73813aafdd2288260abb2160ce0d4cdbac8be"}},
  #                          :main-opts ["-m" "find-deps.core"]}}}
  # ''; in "${pkgs.writeText "_" _}";

  # shell
  environment.variables.ZDOTDIR = "/etc";
  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.shellAliases = {
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

    direnv = ''
      eval "$(direnv hook zsh)"'';

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

    nix-shell-auto-enter = ''
      add-zsh-hook -Uz chpwd (){ [[ -f shell.nix ]] && nix-shell }'';

    terminal-title = ''
      precmd() { print -Pn "\e]0;TTY\a" }
      preexec() { print -Pn "\e]0;$1\a" }'';

    vim-mode = ''
      bindkey -v

      export KEYTIMEOUT=1

      autoload -U edit-command-line; zle -N edit-command-line
      autoload -U select-bracketed; zle -N select-bracketed
      autoload -U select-quoted; zle -N select-quoted
      autoload -U surround; zle -N delete-surround surround; zle -N change-surround surround; zle -N add-surround surround

      bindkey -M vicmd '^x^e' edit-command-line; bindkey -M viins '^x^e' edit-command-line
      bindkey -M vicmd 'H' run-help

      bindkey ''${terminfo[kcbt]:-^\[\[Z} reverse-menu-complete

      bindkey '^n' expand-or-complete
      bindkey '^p' reverse-menu-complete

      for m in visual viopp; do
        for c in {a,i}''${(s..)^:-'()[]{}<>bB'}; do
          bindkey -M $m $c select-bracketed
        done
      done
      for m in visual viopp; do
        for c in {a,i}{\',\",\`}; do
          bindkey -M $m $c select-quoted
        done
      done

      bindkey -a cs change-surround
      bindkey -a ds delete-surround
      bindkey -a ys add-surround
      bindkey -M visual S add-surround

      # change cursor shape with mode
      function zle-keymap-select zle-line-init zle-line-finish {
        case $KEYMAP in
          vicmd) print -n '\033[1 q' ;;
          viins|main) print -n '\033[5 q' ;;
        esac
      }
      zle -N zle-line-init; zle -N zle-line-finish; zle -N zle-keymap-select'';
  in concatStringsSep "\n" [
    "setopt autocd"
    autopair
    completion
    direnv
    fast-syntax-highlighting
    global-aliases
    globbing
    history
    # nix-shell-auto-enter
    terminal-title
    vim-mode
    fzf ];

  environment.etc."gitconfig".text = let
    global-exclude-patterns = let
      emacs = [ "*~" "\\#*#" "\\.#*" ];
    in
      emacs;
  in with pkgs; generators.toINI {} {
    user = with import /home/avo/lib/credentials.nix; { inherit name; email = email.address; };
    alias = {
      am = "commit --all --amend --no-edit";
      ap = "add --patch";
      ci = "commit";
      co = "checkout";
      dc = "diff --cached";
      di = "diff";
      st = "status --short"; };
    core.pager = "${gitAndTools.diff-so-fancy}/bin/diff-so-fancy | ${wrapped.less}/bin/less -X";
    core.excludesFile = "${writeText "_" (concatStringsSep "\n" global-exclude-patterns)}";
    push.default = "current"; };

 systemd.services.remotectl =
   (import (pkgs.fetchFromGitHub {
     owner = "lessrest";
     repo = "restless-cgi";
     rev = "bf95bccc2ce65bcda1b91a149a2764d97b185319";
     sha256 = "0kfkcdskij3ngv43ajlhwm31yqy3a3mbnx9kbdjaqhp0179cjx8j";
   }) { inherit pkgs; }) {
     port = 1988;
     user = "root";
     scripts = {
       suspend = ''
         #!${pkgs.bash}/bin/bash
         systemctl suspend
       '';
     };
   };

  # ChromeCast
  networking.firewall.allowedTCPPorts = [ 1988 8008 8009 5556 5558 ];
  networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60000; } ];
}
