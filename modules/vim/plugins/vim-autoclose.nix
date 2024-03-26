with (import <nixpkgs> { });

vimUtils.buildVimPlugin {
  name = "vim-autoclose";
  src = fetchFromGitHub {
    owner = "Townk";
    repo = "vim-autoclose";
    rev = "a9a3b7384657bc1f60a963fd6c08c63fc48d61c3";
    sha256 = "12jk98hg6rz96nnllzlqzk5nhd2ihj8mv20zjs56p3200izwzf7d";
  };
}
