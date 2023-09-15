{
  services.nextdns = {
    enable = true;
    arguments = [ "-config" "${builtins.getEnv "NEXTDNS_SETUP_ID"}.dns.nextdns.io" ];
  };
}
