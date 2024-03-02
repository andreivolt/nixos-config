# display a summary of changes after nixos-rebuild
{
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
          /run/current-system "$systemConfig"
    '';
  };
}
