let rev = "fd3be17ace1aa22ed6b1d0bd01a979deb098cbbd";
in let url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
in import (builtins.fetchTarball url)
