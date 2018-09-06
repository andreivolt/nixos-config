{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ gitAndTools.git-hub ];

  environment.etc."git/config".text = lib.mkAfter (lib.generators.toINI {} {
    hub = with (import ../credentials.nix).github; {
      username = user;
      oauthtoken = token;
    };
  });
}
