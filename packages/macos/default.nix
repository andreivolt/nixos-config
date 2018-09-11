self: super: with super; {

macos = writeShellScriptBin "macos" ''
  exec setsid &>/dev/null sudo \
    ${kvm}/bin/qemu-system-x86_64 \
      -enable-kvm \
      -m 6G \
      -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+aes,+xsave,+avx,+xsaveopt,avx2,+smep \
      -smp 4,cores=2 \
      -machine pc-q35-2.9 \
      -usb -device usb-kbd -device usb-tablet \
      -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
      -drive if=pflash,format=raw,readonly,file=${builtins.toString ./OVMF_CODE.fd} -drive if=pflash,format=raw,file=${builtins.toString ./OVMF_VARS-1024x768.fd} \
      -smbios type=2 \
      -device ich9-intel-hda -device hda-duplex \
      -device ide-drive,bus=ide.2,drive=Clover -drive id=Clover,if=none,snapshot=on,format=qcow2,file=${builtins.toString ./Clover.qcow2} \
      -device ide-drive,bus=ide.1,drive=MacHDD -drive id=MacHDD,if=none,file=/home/avo/lib/macos.raw,format=raw \
      -netdev user,id=net0 -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
      -redir tcp:10022::22 \
      -monitor stdio'';

macos-nixos-rebuild = writeShellScriptBin "macos-nixos-rebuild" ''
  scp -P 10022 ${builtins.toString ./configuration.nix} a@localhost:.nixpkgs/darwin-configuration.nix

  ssh a@localhost -p 10022 "bash -lic '
    if [[ ! -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
      sh <(curl https://nixos.org/nix/install) --no-daemon
      nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
      ./result/bin/darwin-installer
    fi

    source ~/.nix-profile/etc/profile.d/nix.sh

    sudo -E nix-channel --update

    sudo -E darwin-rebuild switch'" '';

# sudo sh -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
# security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k password
# security unlock-keychain -p ${macosvm_password}

}
