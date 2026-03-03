# On-screen AZERTY keyboard for tablet mode
# Auto-shows on text input focus via input-method-v2
# Show/hide via SIGUSR2/SIGUSR1 (used by autorotate + bindswitch)
{ inputs, ... }: {
  imports = [ inputs.osk.nixosModules.default ];
  services.osk.enable = true;
}
