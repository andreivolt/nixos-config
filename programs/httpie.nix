{
  home-manager.users.avo.programs.httpie = {
    enable = true;

    defaultOptions = [
      "--pretty" "format"
      "--session" "default"
    ];
  };
}
