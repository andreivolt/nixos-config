{
  BG = "& exit";
  C = "| wc -l";
  E = "| $EDITOR -";
  # G = ''|& grep "${grep_options:+"${grep_options}"}'';
  G = "| grep";
  H = "| head -n $(( +LINES?LINES-4:10 ))"; # use as many rows as possible
  # H = "| head";
  HL =" --help |& less -r"; # display help in pager
  L = "| nvimpager";
  # L = "| $PAGER";
  LL ="|& less -r";
  N = "&>/dev/null"; # TODO no output
  NE = "2>/dev/null";
  # NE = "2>|/dev/null"; # no errors
  NO = "&>|/dev/null"; # no output
  NUL = "&>/dev/null";
  S = "| sort -u";
  SL ="| sort | less";
  # T = "| tail";
  T = "| tail -n $(( +LINES?LINES-4:10 ))"; # use as many rows as possible
  UUID = "$(uuidgen | tr -d \\n)";
  X = "| xargs";
}
