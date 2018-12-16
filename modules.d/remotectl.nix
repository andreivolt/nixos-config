{ pkgs, ... }:

{
 systemd.services.remotectl =
   (import (pkgs.fetchFromGitHub {
     owner = "lessrest";
     repo = "restless-cgi";
     rev = "bf95bccc2ce65bcda1b91a149a2764d97b185319";
     sha256 = "0kfkcdskij3ngv43ajlhwm31yqy3a3mbnx9kbdjaqhp0179cjx8j";
   }) { inherit pkgs; }) {
     port = 1988;
     user = "root";
     scripts = {
       suspend = ''
         #!${pkgs.bash}/bin/bash
         systemctl suspend
       '';
     };
   };
 }
