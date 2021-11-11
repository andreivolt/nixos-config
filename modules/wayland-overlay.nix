let rev = "51930bd55223f3d9e4428f6750e4ff80cca2815d";
in let url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
in import (builtins.fetchTarball url)
