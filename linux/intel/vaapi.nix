# Intel VA-API hardware video acceleration
{ pkgs, lib, ... }: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # Use VA-GL wrapper to avoid VDPAU nvidia probe warnings
  environment.variables.VDPAU_DRIVER = "va_gl";

  # Configure mpv to use VAAPI for hardware decoding
  home-manager.sharedModules = [
    {
      programs.mpv.config = {
        hwdec = lib.mkForce "vaapi";
      };
    }
  ];
}
