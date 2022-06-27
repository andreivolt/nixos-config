{
  UUID = "$(uuidgen | tr -d \\n)";
  G = "| grep";
  C = "| wc -l";
  L = "| $PAGER";

  E = "| $EDITOR -";

  # use as many rows as possible
  H = "| head -n $(( +LINES?LINES-4:10 ))";
  T= "| tail -n $(( +LINES?LINES-4:10 ))";

  NE = "2>|/dev/null"; # no errors
  NO = "&>|/dev/null"; # no output
  N = "&>/dev/null"; # TODO no output

  BG = "& exit";
  # G = ''|& grep "${grep_options:+"${grep_options}"}'';
  HL =" --help |& less -r"; # display help in pager
  LL ="|& less -r";
  SL ="| sort | less";
  S = "| sort -u";
}
