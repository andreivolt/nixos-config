{
  home-manager.users.avo.home.file."hub".text = ''
    ---
    github.com:
    - user: andreivolt
      oauth_token: ${builtins.getEnv "GITHUB_TOKEN"}
  '';
}
