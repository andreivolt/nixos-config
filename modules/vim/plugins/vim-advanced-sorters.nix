with (import <nixpkgs> { });

vimUtils.buildVimPlugin {
  name = "vim-advanced-sorters";
  src = fetchFromGitHub {
    owner = "inkarkat";
    repo = "vim-AdvancedSorters";
    rev = "8e033256ebb8901cf430d7cdb85856bbe531b446";
    sha256 = "0vnc8xx1dxk558yis2m3a6yp62rygya14w0m0l6h43wl6zfwwqqy";
  };
}
