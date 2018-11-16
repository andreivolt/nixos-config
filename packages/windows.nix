self: super: with super; {

windows = let
  image_path = "/var/lib/libvirt/images/windows.raw";
in writeShellScriptBin "windows" ''
  sudo \
    ${kvm}/bin/qemu-system-x86_64 \
      -enable-kvm \
      -daemonize \
      -smp 4 -m 4G -cpu host \
      -drive file=${image_path},format=raw,if=virtio \
      -device virtio-serial-pci -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent -spice unix,addr=/tmp/vm_spice.socket,disable-ticketing \
      -usbdevice tablet

  setsid &>/dev/null sudo \
    ${virt-viewer}/bin/remote-viewer spice+unix:///tmp/vm_spice.socket'';


}
