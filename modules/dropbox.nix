{
  home-manager.users.andrei.services.dropbox.enable = true;

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 100000;
}
