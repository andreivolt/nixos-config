{ pkgs, ... }:

let
  plaintextify = "${pkgs.avo-scripts}/bin/plaintextify < %s; copiousoutput";
  libreoffice = "${pkgs.libreoffice}/bin/libreoffice %s";

in {
  environment.etc."mailcap".text =  ''
    application/doc;
    application/msword;                                                        ${plaintextify}
    application/pdf;                                                           ${pkgs.zathura}/bin/zathura %s pdf
    application/vnd.ms-powerpoint;                                             ${libreoffice}
    application/vnd.ms-powerpoint;                                             ${plaintextify}
    application/vnd.openxmlformats-officedocument.presentationml.presentation; ${libreoffice}
    application/vnd.openxmlformats-officedocument.presentationml.presentation; ${plaintextify}
    application/vnd.openxmlformats-officedocument.presentationml.slideshow;    ${libreoffice}
    application/vnd.openxmlformats-officedocument.presentationml.slideshow;    ${plaintextify}
    application/vnd.openxmlformats-officedocument.spreadsheetmleet;            ${plaintextify}
    application/vnd.openxmlformats-officedocument.wordprocessingml.document;   ${plaintextify}
    image;                                                                     ${pkgs.sxiv}/bin/sxiv %s
    text/html;                                                                 ${pkgs.qutebrowser}/bin/qutebrowser-open;
    text/html;                                                                 ${pkgs.w3m}/bin/w3m -o display_link=true -o display_link_number=true -dump -I %{charset} -cols 72 -T text/html %s; nametemplate=%s.html; copiousoutput
  '';
}
