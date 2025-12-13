{
  writeShellApplication,
  uv,
}:
writeShellApplication {
  name = "twscrape";
  runtimeInputs = [uv];
  text = ''
    ACCOUNT_DB="$HOME/Google Drive/My Drive/twscrape/accounts.db"

    if [[ ! -f "$ACCOUNT_DB" ]]; then
        echo "error: account database not found at $ACCOUNT_DB" >&2
        echo "please run 'twscrape add_accounts' first to set up your accounts" >&2
        exit 1
    fi

    exec uv tool run twscrape --db "$ACCOUNT_DB" "$@"
  '';
}
