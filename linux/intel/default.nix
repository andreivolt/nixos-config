# Generic Intel CPU configuration
{ ... }: {
  imports = [
    ./vaapi.nix
  ];

  # Distribute hardware interrupts across CPUs (reduces CPU0 overload)
  services.irqbalance.enable = true;

  # Update microcode for Spectre/Meltdown/GDS mitigations
  hardware.cpu.intel.updateMicrocode = true;
}
