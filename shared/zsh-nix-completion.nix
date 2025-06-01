{pkgs, ...}: {
  environment.systemPackages = [pkgs.nix-zsh-completions];

  environment.pathsToLink = ["/share/zsh"];
}
