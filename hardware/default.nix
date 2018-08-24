{
  imports = [
    ./audio.nix
    ./keyboard.nix
    ./nvidia.nix
    ./printing.nix
    ./touchpad.nix
  ];

  hardware.bluetooth.enable = true;
}
