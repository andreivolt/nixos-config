{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs;
    [ vim
      # osxfuse sshfs
      darwin.xcode ];

  nixpkgs.config.allowUnfree = true;

  # auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;
  programs.zsh.enable = true;

  # used for backwards compatibility
  system.stateVersion = 3;

  nix.maxJobs = 2;
  nix.buildCores = 2;
}
