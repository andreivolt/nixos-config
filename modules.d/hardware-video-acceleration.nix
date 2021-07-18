{ pkgs, ... }:

{
  # nixpkgs.config.packageOverrides = pkgs: {
  #   vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  # };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      # vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  home-manager.users.avo.programs.mpv.config = {
    hwdec = "auto-safe";
    vo = "gpu";
    profile = "gpu-hq";
    gpu-context = "wayland";
  };
}
