{pkgs, ...}: {
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0;

  home-manager.sharedModules = [
    {
      home.packages = [pkgs.reptyr];
    }
  ];
}
