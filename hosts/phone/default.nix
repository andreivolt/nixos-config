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

  # Home Manager config
  home-manager = {
    useGlobalPkgs = true;
    config = {pkgs, ...}: {
      home.stateVersion = "24.05";

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

      # Minimal zsh config - source dotfiles
      programs.zsh = {
        enable = true;
        enableCompletion = false;
        initExtra = "source ~/.config/zsh/rc.zsh";
      };
    };
  };
}
