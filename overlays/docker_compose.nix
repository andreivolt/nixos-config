self: pkgs: rec {

docker_compose = with pkgs; stdenv.lib.overrideDerivation pkgs.docker_compose (attrs: {
  installPhase = pkgs.docker_compose.installPhase + ''
    mkdir -p $out/share/zsh/site-functions
    cp contrib/completion/zsh/_docker-compose $out/share/zsh/site-functions
  '';
});

}
