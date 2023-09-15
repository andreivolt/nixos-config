# resolve *.test to localhost
{
  services.dnsmasq = {
    enable = true;
    settings.addresses.test = "127.0.0.1";
  };
}
