{
  writeShellApplication,
  dnsutils,
}:
writeShellApplication {
  name = "whatismyip";
  runtimeInputs = [dnsutils];
  text = ''
    exec dig +short whoami.akamai.net @ns1-1.akamaitech.net
  '';
}
