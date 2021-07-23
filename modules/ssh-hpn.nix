# high performance SSH
{
  programs.ssh.package = pkgs.openssh_hpn;
  nixpkgs.config.permittedInsecurePackages = [ "openssh-with-hpn-8.4p1" ];
}

