{
  writeShellApplication,
  docker,
  fzf,
  gawk,
}:
writeShellApplication {
  name = "docker-compose-stop";
  runtimeInputs = [docker fzf gawk];
  text = ''
    docker compose ls |
      tail -n +2 |
      awk '{print $1}' |
      fzf --multi --prompt="Select project(s) to stop: " |
      xargs -r -I {} docker compose -p {} down
  '';
}
