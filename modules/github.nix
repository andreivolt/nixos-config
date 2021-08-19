{
  home-manager.users.avo.xdg.configFile."hub".text = ''
    ---
    github.com:
    - user: andreivolt
      oauth_token: ${builtins.getEnv "GITHUB_TOKEN"}
  '';
}
