self: super: with super; {

sms = writeShellScriptBin "sms" ''
  ${self.openssh}/bin/ssh 192.168.1.19 -p 8022 "
    if [[ $1 =~ ^[a-zA-Z] ]]; then
      number=\$(
        termux-contact-list |
        jq '.[] | [ .name, .number ] | @tsv' -r |
        grep -i '^$1' |
        awk '{ print \$NF }')
    else
      number=$1
    fi

    shift
    message="$*"

    termux-sms-send \$number '$message' "'';
}
