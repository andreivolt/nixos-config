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
    ../shared/moreutils-without-parallel.nix
    ../shared/nix.nix
    ../shared/ssh.nix
    ../shared/zsh-nix-completion.nix
    ./brother-printer.nix
    ./brother-scanner.nix
    ./docker.nix
    ./lowbatt.nix
    ./networkmanager.nix
    ./rclone.nix
    ./tor.nix
    ./v4l2loopback.nix
  ];

  console.keyMap = "fr";
  console.earlySetup = true;
  console.font = "ter-132n";
  console.packages = [pkgs.terminus_font];

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
  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };
  services.sshd.enable = true;
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--operator=andrei" "--login-server=https://hs.avolt.net"];
  };

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
  environment.variables.LC_TIME = "C.UTF-8";
  environment.systemPackages = import "${inputs.self}/packages.nix" pkgs;

  
}
