{
  nixpkgs.overlays = [
    (self: super: {
      mozilla = let
        src = fetchTarball {url = "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz";};
      in
        import "${src}/firefox-overlay.nix";
    })
  ];
}
