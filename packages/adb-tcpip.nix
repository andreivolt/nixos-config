self: super: with super; {

adb-tcpip = with androidenv; writeShellScriptBin "adb-tcpip" ''
  ${platformTools}/bin/adb tcpip 5555
  ${platformTools}/bin/adb connect 192.168.1.11'';

}
