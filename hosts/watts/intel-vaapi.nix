{pkgs, lib, ...}: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # Configure mpv to use VAAPI for hardware decoding
  home-manager.sharedModules = [
    {
      programs.mpv.config = {
        hwdec = lib.mkForce "vaapi";
      };
    }
  ];
}
