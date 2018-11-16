self: super: with super; {

adb-tcpip = writeShellScriptBin "adb-tcpip" (with androidenv; ''
  ${platformTools}/bin/adb tcpip 5555
  ${platformTools}/bin/adb connect 192.168.1.11'');

}
