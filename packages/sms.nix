self: super: with super; {

sms = writeShellScriptBin "sms" ''
  phone_number=$1
  shift

  message="$*"

  ${self.openssh}/bin/ssh 192.168.1.19 -p 8022 "
    termux-sms-send $phone_number '$message'"'';

}
