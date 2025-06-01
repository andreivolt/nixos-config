{
  home-manager.users.andrei.programs.swaylock = {
    enable = true;
    settings = {
      indicator-thickness = 100;
      indicator-radius = 50;
      color = "000000";
      inside-color = "006400ff";
      ring-color = "006400ff";
      line-color = "006400ff";
      key-hl-color = "00ff00ff";
      bs-hl-color = "ff0000ff";
      separator-color = "006400ff";
      inside-ver-color = "00ff00ff";
      inside-wrong-color = "ff0000ff";
      ring-ver-color = "006400ff";
      ring-wrong-color = "ff0000ff";
      text-color = "00000000";
      text-ver-color = "00000000";
      text-wrong-color = "00000000";
      layout-bg-color = "00000000";
      layout-border-color = "00000000";
      layout-text-color = "00000000";
    };
  };

  security.pam.services.swaylock.text = "auth include login";
}
