{
  home-manager.users.andrei.xdg.configFile."hub".text = ''
    ---
    github.com:
    - user: andreivolt
      oauth_token: ${builtins.getEnv "GITHUB_TOKEN"}
  '';
}
