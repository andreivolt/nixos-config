# resolve *.test to localhost
{
  services.dnsmasq = {
    enable = true;
    addresses.test = "127.0.0.1";
  };
}
