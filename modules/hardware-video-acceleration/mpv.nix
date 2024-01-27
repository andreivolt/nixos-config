{
  home-manager.users.andrei.programs.mpv.config = {
    hwdec = "auto-safe";
    vo = "gpu";
    profile = "gpu-hq";
    gpu-context = "wayland";
  };
}
