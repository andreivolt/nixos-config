self: super:

with super.lib;
with builtins;

{
  avo = {
    pushover = super.callPackage ./pushover {};
    wsta = super.callPackage ./wsta {};
    adi1090x-plymouth = super.callPackage ./adi1090x-plymouth { };
  };
}

