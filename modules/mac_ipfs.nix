{ pkgs, ... }:

{
  launchd.daemons.ipfs = {
    script = "${pkgs.ipfs}/bin/ipfs daemon";

    serviceConfig = {
      Label = "ipfs";
      RunAtLoad = true;
      KeepAlive.NetworkState = true;
    };
  };
}
