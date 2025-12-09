# SSH authorized_keys for macOS via home-manager
{ lib, ... }:

let
  keys = import ../../shared/ssh-keys.nix;
  allUserKeys = lib.attrValues keys.userKeys;
  authorizedKeysContent = lib.concatStringsSep "\n" allUserKeys + "\n";

in {
  # Write as actual file (not symlink) - sshd rejects symlinks due to StrictModes
  home-manager.users.andrei = { lib, ... }: {
    home.activation.authorizedKeys =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cat > "$HOME/.ssh/authorized_keys" <<'EOF'
${authorizedKeysContent}EOF
        chmod 600 "$HOME/.ssh/authorized_keys"
      '';
  };
}
