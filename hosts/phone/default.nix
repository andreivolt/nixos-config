{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  system.stateVersion = "24.05";

  # Packages
  environment.packages = import "${inputs.self}/packages/phone.nix" pkgs;

  # Use zsh as default shell
  user.shell = "${pkgs.zsh}/bin/zsh";

  # termux.properties
  terminal.font = ./font.ttf;

  # Nix settings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Android integration - termux commands
  android-integration = {
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true; # alias to termux-open
  };

  # Home Manager config
  home-manager = {
    useGlobalPkgs = true;
    config = {pkgs, ...}: {
      home.stateVersion = "24.05";
      home.enableNixpkgsReleaseCheck = false;

      # .termux/termux.properties
      home.file.".termux/termux.properties".text = ''
        allow-external-apps=true
        terminal-margin-horizontal=0
        terminal-transcript-rows=2000
        bell-character=ignore
      '';

      # Shortcuts for Termux widget
      home.file.".shortcuts/copy" = {
        text = ''
          #!/data/data/com.termux.nix/files/usr/bin/bash
          termux-clipboard-get | ssh mac pbcopy
        '';
        executable = true;
      };

      home.file.".shortcuts/paste" = {
        text = ''
          #!/data/data/com.termux.nix/files/usr/bin/bash
          ssh mac pbpaste | termux-clipboard-set
        '';
        executable = true;
      };

      # Boot script to start sshd on Tailscale interface
      home.file.".termux/boot/start-sshd.sh" = {
        text = ''
          #!/data/data/com.termux.nix/files/usr/bin/bash
          TAILSCALE_IP=$(ifconfig 2>/dev/null | grep -A 1 tun0 | grep inet | awk '{print $2}')
          if [ -n "$TAILSCALE_IP" ]; then
            sed -i '/^ListenAddress/d' $PREFIX/etc/ssh/sshd_config
            echo "ListenAddress $TAILSCALE_IP" >> $PREFIX/etc/ssh/sshd_config
          fi
          sshd
        '';
        executable = true;
      };

      # SSH config: disable password auth
      home.file.".ssh/sshd_config.d/auth.conf".text = ''
        PasswordAuthentication no
      '';

      # SSH client config - host aliases for Tailnet machines
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "riva" = {
            hostname = "riva.tail.avolt.net";
            user = "andrei";
          };
          "watts" = {
            hostname = "watts.tail.avolt.net";
            user = "andrei";
          };
          "ampere" = {
            hostname = "ampere.tail.avolt.net";
            user = "andrei";
          };
          "mac" = {
            hostname = "mac.tail.avolt.net";
            user = "andrei";
          };
        };
      };

      # Known hosts for Tailnet machines
      home.file.".ssh/known_hosts".text = ''
        riva,riva.tail.avolt.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLnH+F2bxmtxgUnNN9CeNBt6n43H3u2TmmPghgyFRN8
        watts,watts.tail.avolt.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIM2FRYqJEu/63o4VROBZ9+v6YWjfCr+pxyObaaP4FGv
        ampere,ampere.tail.avolt.net,hs.avolt.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9YxDDUlniLwYScXpg5shPmLPz0UFWe52+Rz2yjWM2k
      '';

      # Minimal zsh config - source dotfiles
      programs.zsh = {
        enable = true;
        enableCompletion = false;
        initExtra = "source ~/.config/zsh/rc.zsh";
      };

      # Direnv (shared with other hosts)
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };
    };
  };
}
