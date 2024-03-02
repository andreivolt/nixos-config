{
  home-manager.users.andrei = { pkgs, lib, ... }: rec {
    programs.zsh.initExtra = lib.mkBefore ''
      fpath+=(${pkgs.nix-zsh-completions}/share/zsh/site-functions) # enableCompletion is set to false
    '';
  };
}
