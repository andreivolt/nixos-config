rec {
  ".." = "cd ..";

  # ls = "ls -F --human-readable --group-directories-first";
  lsd = "lsd --classify";

  open = "xdg-open";
  yt-dlp = "yt-dlp --cookies-from-browser firefox";

  ls = "lsd";

  # la = "ls -A"; # show hidden files except "." and ".."
  la = "lsd --all";

  ll = "ls -l";
  lla = "ll --all";
  l = "ls -1";

  diff = "colordiff";

  vim = "nvim";
  vi = "nvim";

  da = "du -sch";

  j = "jobs";

  gsp = "git stash && git pull";
  gspp = "${gsp} && git stash pop";
  slugify = "iconv -t ascii//TRANSLIT | sed -E 's/[~\^]+//g' | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+\|-+$//g' | tr A-Z a-z";

  "git" = "GPG_TTY=$(tty) git";
  "rm" = "rm --verbose";
  "grep" = "grep --color";
  "info" = "info --vi-keys"; # vim
}
