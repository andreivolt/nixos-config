self: super:

with super.lib;
with builtins;

{
  avo = {
    zprint = super.callPackage ./zprint {};
    pushover = super.callPackage ./pushover {};
  };
}

