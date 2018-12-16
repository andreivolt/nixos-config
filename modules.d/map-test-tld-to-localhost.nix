{
  services.dnsmasq = {
    enable = true;
    extraConfig = "address=/test/127.0.0.1";
  };
}
