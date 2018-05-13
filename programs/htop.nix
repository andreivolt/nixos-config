{
  home-manager.users.avo.programs.htop = {
    enable = true;
    
    fields = [
      "USER"
      "PRIORITY"
      "STATE"
      "PERCENT_CPU"
      "PERCENT_MEM"
      "TIME"
      "IO_READ_RATE"
      "IO_WRITE_RATE"
      "STARTTIME"
      "COMM"
    ];
    accountGuestInCpuMeter = false;
    colorScheme = 6;
    hideUserlandThreads = true;
    meters = {
      left = [
        "Memory"
        "CPU"
        "LoadAverage"
      ];
      right = [
        "Tasks"
        "Uptime"
      ];
    };
  };
}
