{
  nixpkgs.overlays = [
    (self: super: {
      unstable = import <nixpkgs-unstable> { };
    })
  ];
}
