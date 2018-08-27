{ config, lib, pkgs, ... }:

{
  environment.systemPackages = let
    nixos-config = pkgs.writeText "configuration.nix" ''
      { config, pkgs, ... }:

      {
        environment.systemPackages = with pkgs; [
          fastlane
          nodejs
          ruby_2_5
        ];

        environment.variables = {
          LC_ALL = "en_us.UTF-8";
          LANG = "en_us.UTF-8";
        };

        programs.zsh.enable = true;

        system.stateVersion = 2;

        nix.maxJobs = 1;
        nix.buildCores = 1;
      }
    '';

    macos-vm = with pkgs; let
      machine-xml = pkgs.writeText "machine.xml" ''
        <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
          <name>macos</name>
          <title>macos</title>
          <description># echo 1 &gt; /sys/module/kvm/parameters/ignore_msrs</description>
          <memory unit='KiB'>4194304</memory>
          <currentMemory unit='KiB'>4194304</currentMemory>
          <vcpu placement='static'>2</vcpu>
          <os>
            <type arch='x86_64' machine='pc-q35-2.4'>hvm</type>
            <kernel>/var/lib/libvirt/images/enoch_rev2889_boot</kernel>
          </os>
          <features>
            <acpi/>
            <kvm>
              <hidden state='on'/>
            </kvm>
          </features>
          <cpu mode='custom' match='exact'>
            <model fallback='allow'>Penryn</model>
          </cpu>
          <devices>
            <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
            <disk type='file' device='disk'>
              <driver name='qemu' type='qcow2'/>
              <source file='/var/lib/libvirt/images/macos.qcow2'/>
              <target dev='sda' bus='sata'/>
              <boot order='1'/>
              <address type='drive' controller='0' bus='0' target='0' unit='0'/>
            </disk>
            <interface type='bridge'>
              <mac address='52:54:00:8e:e2:66'/>
              <source bridge='br0'/>
              <model type='e1000-82545em'/>
              <address type='pci' domain='0x0000' bus='0x02' slot='0x02' function='0x0'/>
            </interface>
            <graphics type='vnc' port='5900' autoport='no' listen='127.0.0.1'>
              <listen type='address' address='127.0.0.1'/>
            </graphics>
            <video>
              <model type='vmvga' vram='16384' heads='1'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
            </video>
            <memballoon model='none'/>
          </devices>
          <qemu:commandline>
            <qemu:arg value='-usb'/>
            <qemu:arg value='-device'/>
            <qemu:arg value='usb-mouse,bus=usb-bus.0'/>
            <qemu:arg value='-device'/>
            <qemu:arg value='usb-kbd,bus=usb-bus.0'/>
            <qemu:arg value='-device'/>
            <qemu:arg value='isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc'/>
            <qemu:arg value='-smbios'/>
            <qemu:arg value='type=2'/>
            <qemu:arg value='-cpu'/>
            <qemu:arg value='Penryn,vendor=GenuineIntel'/>
          </qemu:commandline>
        </domain>
      '';

      setup = pkgs.writeText "setup.sh" ''
        sudo chsh -s /bin/zsh avo

        curl https://nixos.org/nix/install | sh

        scp ~/.dotfiles/.npmrc macos.local:

        nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
        ./result/bin/darwin-installer

        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k password

        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

        brew install ruby
        brew install graphicsmagick

        mkdir ~/proj

        security unlock-keychain -p ${macosvm_password}

        /etc/sudoers
        %wheel    ALL=(ALL)   NOPASSWD: ALL

        brew cask install osxfuse
        brew install sshfs
      '';

    in stdenv.mkDerivation rec {
      name = "macos-vm";

      src = [];

      unpackPhase = "true";

      installPhase = "mkdir $out";
    };
  in [ macos-vm ];
}
