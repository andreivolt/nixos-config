# Fix openssl_1_1 patch after 3.0.19 update (nixpkgs#485055, pending nixos-unstable)
inputs: final: prev: {
  openssl_1_1 = prev.openssl_1_1.overrideAttrs (oldAttrs: {
    patches = [
      (builtins.elemAt oldAttrs.patches 0) # nix-ssl-cert-file.patch
    ];
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace include/internal/cryptlib.h \
        --replace-fail 'OPENSSLDIR "/cert.pem"' '"/etc/ssl/certs/ca-certificates.crt"'
    '';
  });
}
