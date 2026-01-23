# Enable notch support for MacBooks with notch displays
# (MacBook Pro 14", 16", MacBook Air 15")
{ ... }: {
  boot.kernelParams = [ "appledrm.show_notch=1" ];
}
