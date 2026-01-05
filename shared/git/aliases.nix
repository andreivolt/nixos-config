{
  ci = "commit";
  co = "checkout";
  dc = "diff --cached";
  di = "diff --word-diff=color";
  st = "status --short";
  amend = "commit --amend --reuse-message=HEAD";
  conflicts = "diff --diff-filter=U --name-only --relative";
  am = "commit --all --amend --no-edit";
  ca = "commit --amend -C HEAD";
  pf = "push -f";
  tree = "!git ls-files | tree --fromfile -a";
  ap = "add --patch";
  l = "log --exclude='refs/original/*' --graph --format=format:'%C(bold blue)%h%C(bold yellow)%d%C(reset) - %C(bold green)%<(14)%ar%C(reset) %s %C(dim white)- %<(12,trunc)%an%C(reset)'";
  la = "!git l --all";
  ups = "!git add --update && git commit --amend --reuse-message HEAD && git push --force";
  lb = "!git reflog show --pretty=format:'%gs ~ %gd' --date=relative | grep 'checkout:' | grep -oE '[^ ]+ ~ .*' | awk -F~ '!seen[$1]++' | awk -F' ~ HEAD@{' '{printf(\"  \\033[33m%s: \\033[37m %s\\033[0m\\n\", substr($2, 1, length($2)-1), $1)}'";
  af = "add --force";
}
