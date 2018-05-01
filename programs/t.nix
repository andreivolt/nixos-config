let credentials = import ../credentials.nix;
in {
  username = "andreivolt";
  credentials = credentials.twitter;
}
