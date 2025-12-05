# Base NixOS configuration - CLI only (no GUI)
# For desktop environments, also import gui.nix
{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ../shared/dnsmasq.nix
    ../shared/gnupg.nix
    ../shared/direnv.nix
    ../shared/nix.nix
    ../shared/ssh.nix
    ../shared/zsh-nix-completion.nix
    ../linux/docker.nix
    ../linux/rclone.nix
  ];

  console.keyMap = "fr";
  console.earlySetup = true;
  console.font = "ter-132n";
  console.packages = [pkgs.terminus_font];

  # Caps -> Escape at kernel level (works in console and Wayland)
  services.udev.extraHwdb = ''
    # HID keyboards (USB, internal Apple, etc.)
    evdev:input:*
     KEYBOARD_KEY_70039=key_esc

    # AT/PS2 keyboards (ThinkPad internal, etc.)
    evdev:atkbd:*
     KEYBOARD_KEY_3a=key_esc
  '';

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  users.users.andrei = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "video" "input"];
  };

  programs.mosh.enable = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--operator=andrei" "--login-server=https://hs.avolt.net"];
  };

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
  environment.variables.LC_TIME = "C.UTF-8";
  environment.systemPackages =
    (import "${inputs.self}/packages/core.nix" pkgs)
    ++ (import "${inputs.self}/packages/linux.nix" pkgs);

  
}
