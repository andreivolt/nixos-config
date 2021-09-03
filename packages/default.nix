self: super:

with super.lib;
with builtins;

{
  avo = {
    pushover = super.callPackage ./pushover {};
    adi1090x-plymouth = super.callPackage ./adi1090x-plymouth { };
  };
}

