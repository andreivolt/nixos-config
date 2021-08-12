tty_icon="\ue795"
preexec () { echo -e "\e]2;$tty_icon $1 ($(print -rD $PWD))\a" }
