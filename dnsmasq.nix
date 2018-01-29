{
  services.dnsmasq = {
    enable = true;
    servers = ["8.8.8.8" "8.8.4.4"];

    extraConfig = ''
      address=/test/127.0.0.1
    '';
  };
}
