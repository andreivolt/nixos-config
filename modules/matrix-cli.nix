{
  home-manager.users.andrei.xdg.configFile."matrixcli/config.py".text = ''
    def password_eval():
        return "${builtins.getEnv "MATRIX_PASSWORD"}"


    accounts = [
        {
            "server": "https://matrix.org/",
            "username": "${builtins.getEnv "MATRIX_USERNAME"}",
            "passeval": password_eval
        }
    ]
  '';
}
