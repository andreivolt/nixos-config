{
  imports = [
    ./audio.nix
    ./keyboard.nix
    ./monitors.nix
    ./nvidia.nix
    ./printing.nix
    ./touchpad.nix
  ];

  hardware.bluetooth.enable = true;
}
