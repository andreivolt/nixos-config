{ lib, pkgs, ... }:

let
  theme = import ./modules.d/theme.nix;

in {
  imports = [
    ./hardware-configuration.nix
    (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos")

    ./modules.d/ad-hosts-block.nix
    ./modules.d/adb.nix
    ./modules.d/alacritty/alacritty.nix
    ./modules.d/audio.nix
    ./modules.d/cloudflare-dns.nix
    ./modules.d/docker.nix
    ./modules.d/fonts.nix
    ./modules.d/low-bat-suspend.nix
    ./modules.d/map-test-tld-to-localhost.nix
    ./modules.d/npm.nix
    ./modules.d/sway.nix
    ./modules.d/tor.nix
    ./modules.d/vim.nix
    # ./modules.d/curl.nix
  ];

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = https://nixos.org/channels/nixos-unstable;
  system.stateVersion = "19.09";

  # automount removable devices
  services.devmon.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "fr";


  # hidpi in console
  console.font = "latarcyrheb-sun32";


  time.timeZone = "Europe/Paris";

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

  # fix Sway "failed to take device"
  hardware.opengl.driSupport = true;

  nix.buildCores = 0;
  nix.gc.automatic = true;
  nix.optimise.automatic = true;
  nix.useSandbox = false;

  users.users.avo.isNormalUser = true;
  users.users.avo.shell = pkgs.zsh;
  users.users.avo.extraGroups = [ "wheel" ];

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = builtins.getEnv "HOSTNAME";

  nixpkgs.config.allowUnfree = true;

  environment.variables.GREP_COLOR = "1";

  environment.variables.LESS = ''
    --RAW-CONTROL-CHARS \
    --ignore-case \
    --no-init \
    --quit-if-one-screen\
  '';

  # block ads

  # fzf
  programs.zsh.shellAliases.fzf = ''
    fzf \
      --color bg:15,fg:8,bg+:4,fg+:0,hl:3,hl+:3,info:15,pointer:12,prompt:8 \
      --no-bold\
  '';

  environment.variables.LS_COLORS = "di=0;35:fi=0;37:ex=0;96:ln=0;37";

  # hardware video acceleration
  hardware.opengl.extraPackages = [ pkgs.vaapiVdpau ];
  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  systemd.user.services.insync = {
    after = [ "network.target" ]; wantedBy = [ "default.target" ];
    script = "${pkgs.insync}/bin/insync start";
    serviceConfig = { Type = "forking"; Restart = "always"; };
  };

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  environment.variables.BROWSER = "browser";
  environment.variables.EDITOR = "vim";
  environment.variables.PAGER = "less";

  # kdeconnect
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];

  home-manager.users.avo = { pkgs, config, ... }: {
    gtk.enable = true;
    gtk.theme.name = "dark";

    # gtk.theme.package = pkgs.gnome-breeze;

    gtk.font.name = "Product Sans 8";

    services.kdeconnect.enable = true;

    home.sessionPath = [ "$HOME/.local/bin" ];
    home.sessionVariables.BROWSER = "google-chrome-stable";

    home.packages = let
      pushover = pkgs.writeScriptBin "pushover" ''
        #!${pkgs.python}/bin/python

        import getopt
        import sys
        import os
        import StringIO
        import httplib
        import urllib


        class Pushover:
            priorities = {"high": 1, "normal": 0, 'low': -1}

            message = ""
            priority = priorities["normal"]
            title = ""
            token = os.environ['PUSHOVER_TOKEN']
            url = None
            user = os.environ['PUSHOVER_USER']

            def exit(self, code):
                sys.exit(code)

            def usage(self):
                file = os.path.basename(__file__)
                print "Usage:   " + file + " [options] <message> <title>"
                print "Stdin:   " + file + " [options] - <title>"
                print "Example: " + file + " \"Hello World\""
                print ""
                print "  -p --priority <high, normal, low>   Default: normal"
                print "  -l --url      <url>                 Link the message to this URL"

            def main(self):
                try:
                    opts, args = getopt.getopt(sys.argv[1:], "hu:t:p:u:c:l:",
                                              ["help",
                                                "user=",
                                                "token=",
                                                "priority=",
                                                "url="])
                except getopt.GetoptError as err:
                    print str(err)
                    self.usage()
                    self.exit(2)

                if len(args) > 0:
                    self.message = args.pop(0)

                    if len(args) > 0:
                        self.title = args.pop(0)

                    for o, a in opts:
                        if o in ("-h", "--help"):
                            self.usage()
                            self.exit(0)
                        elif o in ("-u", "--user"):
                            self.user = a
                        elif o in ("-t", "--token"):
                            self.token = a
                        elif o in ("-p", "--priority"):
                            for name, priority in self.priorities.iteritems():
                                if name == a:
                                    self.priority = priority
                        elif o in ("-l", "--url"):
                            self.url = a

                    if self.message == "-":
                        while True:
                            try:
                                line = sys.stdin.readline().strip()
                                if len(line) > 0:
                                    self.message = line
                                    self.send()
                            except KeyboardInterrupt:
                                break
                            if not line:
                                break

                    else:
                        self.send()

                else:
                    self.usage()
                    self.exit(2)

            def send(self):
                conn = httplib.HTTPSConnection("api.pushover.net:443")
                conn.request("POST", "/1/messages.json",
                            urllib.urlencode({
                                "token": self.token,
                                "user": self.user,
                                "url": self.url,
                                "title": self.title,
                                "message": self.message,
                                "priority": self.priority,
                            }), {"Content-type": "application/x-www-form-urlencoded"})

        if __name__ == "__main__":
            pushover = Pushover()
            pushover.main()
      '';

      colorpicker = pkgs.writeShellScriptBin "colorpicker" ''
        grim -g "$(slurp -p)" -t ppm - | gm convert - -format '%[pixel:p{0,0}]' txt:-
      '';

      moreutilsWithoutParallel = lib.overrideDerivation pkgs.moreutils (attrs: {
        postInstall =
          attrs.postInstall + "\n" +
          "rm $out/bin/parallel $out/share/man/man1/parallel.1";
      });

      zprint = pkgs.stdenv.mkDerivation rec {
        name = "zprint";
        src = pkgs.fetchurl {
          url = "https://github.com/kkinnear/zprint/releases/download/0.4.10/zprintl-0.4.10";
          sha256 = "0iab2gvynb0njhr2vy26li165sc2v6p5pld7ifp6jlf7yj3yr4gl";
        };
        unpackPhase = ":";
        dontStrip = true;
        preFixup =
          let rpath = with pkgs; lib.makeLibraryPath [ zlib ];
          in ''
            patchelf \
              --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${rpath}" \
              $out/bin/zprint
          '';
        installPhase = "mkdir -p $out/bin && cp $src $out/bin/zprint && chmod +x $out/bin/zprint";
      };
    in with pkgs; [
      # chromium
      # kotakogram-desktop
      # libreoffice-fresh
      acpi
      alacritty
      aria
      bc
      chromedriver
      clipman
      clojure
      colorpicker
      curl
      dnsutils
      nodePackages.peerflix
      glpaper
      nodePackages.webtorrent-cli
      wf-recorder
      pamixer
      dtach
      dtrx
      babashka
      t
      ffmpeg-full # -full for ffplay
      file
      firefox
      fzf
      geoip
      gh
      git
      git-hub
      gnumake
      gnupg
      google-chrome
      graphicsmagick
      httpie
      iftop
      imv
      insync
      iotop
      jq
      kdeconnect
      lastpass-cli
      libarchive # bsdtar
      libnotify
      lsof
      mediainfo
      moreutilsWithoutParallel
      mosh
      mpv
      msmtp
      mupdf
      netcat
      nethogs
      nmap
      openssl
      pandoc
      parallel
      patchelf
      pavucontrol
      protonvpn-cli
      psmisc
      pup
      pushover
      python3
      python39Packages.pip
      qemu
      gist
      bat
      (pkgs.callPackage ./packages/zprint.nix {})
      recode
      ripgrep
      rlwrap
      socat
      sox
      spotify
      strace
      sublime3
      surf
      tdesktop
      telnet
      tmate
      torbrowser
      tree
      ungoogled-chromium
      unzip
      usbutils
      vlc
      wget
      xdg_utils
      xfce.thunar
      xurls
      xxd
      youtube-dl
      youtube-viewer
    ];

    programs.direnv.enable = true;
    programs.direnv.enableZshIntegration = true;

    programs.zsh.shellAliases.ls = ''
      LC_COLLATE=C \
        ls \
          --dereference \
          --human-readable \
          --indicator-style=slash \
    '';
    programs.zsh.shellAliases.l = "ls -1";
    programs.zsh.shellAliases.la = "ls -a";
    programs.zsh.shellAliases.ll = "ls -l";

    programs.zsh.shellAliases.grep = "grep --color=auto";
    programs.zsh.shellAliases.rg = "rg --smart-case --colors=match:fg:yellow";
    programs.zsh.shellAliases.vi = "vim";

    programs.zsh.enable = true;

    programs.zsh.enableCompletion = true;

    programs.zsh.initExtra = ''
      unsetopt beep

      setopt \
        case_glob \
        extended_glob \
        glob_complete

      source ${pkgs.fetchFromGitHub {
        owner = "zdharma"; repo = "fast-syntax-highlighting";
        rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e"; sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
      }}/fast-syntax-highlighting.plugin.zsh

      source ${pkgs.fetchFromGitHub {
        owner = "hlissner"; repo = "zsh-autopair";
        rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1"; sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
      }}/autopair.zsh

      bindkey -v

      export KEYTIMEOUT=1

      autoload -U edit-command-line; zle -N edit-command-line
      autoload -U select-bracketed; zle -N select-bracketed
      autoload -U select-quoted; zle -N select-quoted
      autoload -U surround; zle -N delete-surround surround; zle -N change-surround surround; zle -N add-surround surround

      bindkey -M vicmd '^x^e' edit-command-line; bindkey -M viins '^x^e' edit-command-line
      bindkey -M vicmd 'H' run-help

      bindkey -M vicmd v edit-command-line

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

      function zle-keymap-select zle-line-init zle-line-finish {
        case $KEYMAP in
          vicmd) print -n '\033[1 q' ;;
          viins|main) print -n '\033[6 q' ;;
        esac
      }
      zle -N zle-line-init; zle -N zle-line-finish; zle -N zle-keymap-select

      zstyle ':completion:*' menu select
      zstyle ':completion:*' rehash true

      source ${pkgs.fzf}/share/fzf/completion.zsh

      HISTSIZE=99999 SAVEHIST=$HISTSIZE
      HISTFILE=~/.cache/zsh_history

      setopt \
        extended_history \
        hist_ignore_all_dups \
        hist_ignore_space \
        hist_reduce_blanks \
        share_history

      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      prompt_precmd() {
        rehash
        setopt promptsubst

        local jobs; unset jobs
        local prompt_jobs
        for a (''${(k)jobstates}) {
          j=$jobstates[$a];i=\'''''${''${(@s,:,)j}[2]}'
          jobs+=($a''${i//[^+-]/})
        }
        prompt_jobs=""
        [[ -n $jobs ]] && prompt_jobs="["''${(j:,:)jobs}"] "

        PROMPT="%(?.%F{green}.%F{red})%~ $ %f%K{black}%F{white}$prompt_jobs%f%k"
      }
      prompt_opts=(cr percent sp subst)
      autoload -U add-zsh-hook
      add-zsh-hook precmd prompt_precmd

      alias -g H='| head'
      alias -g T='| tail'
      alias -g C='| wc -l'
      alias -g G='| grep'
      alias -g L="| less"
      alias -g M="| most"
      alias -g LL='2>&1 | less'
      alias -g CA='2>&1 | cat -A'
      alias -g NE='2> /dev/null'
      alias -g NUL='> /dev/null 2>&1'
      alias -g P='2>&1| pygmentize -l pytb'
    '';

    home.file.".inputrc".text = ''
      set editing-mode vi

      set completion-ignore-case on
      set show-all-if-ambiguous on

      set keymap vi
      C-r: reverse-search-history
      C-f: forward-search-history
      C-l: clear-screen
      v: rlwrap-call-editor
    '';

    home.file.".gitconfig".text = lib.generators.toINI {} {
      user.name = "Andrei Volt";
      user.email = "andrei@avolt.net";
      alias = {
        am = "commit --all --amend --no-edit";
        ap = "add --patch";
        ci = "commit";
        co = "checkout";
        dc = "diff --cached";
        di = "diff";
        st = "status --short";
      };
      core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -X";
      push.default = "current";
      hub.oauthtoken = builtins.getEnv "GITHUB_TOKEN";
    };
  };

  environment.variables.PUSHOVER_USER = builtins.getEnv "PUSHOVER_USER";
  environment.variables.PUSHOVER_TOKEN = builtins.getEnv "PUSHOVER_TOKEN";

  services.upower.enable = true;
  services.batteryNotifier = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  networking.enableIPv6 = false;

  networking.networkmanager.enable = true;

  environment.variables.GDK_SCALE = "2";
}
