{ pkgs, ... }:

{
  services.dictd = {
    enable = true;
    DBs = with pkgs.dictdDBs; [ wiktionary wordnet ];
  };

  environment.etc."dict.conf".text = ''
    server localhost
  '';
}
