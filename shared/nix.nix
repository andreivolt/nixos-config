{
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.optimise.automatic = true;
}
