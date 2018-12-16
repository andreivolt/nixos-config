# fix conflict with GNU parallel

self: super: with super; {

moreutils = lowPrio super.moreutils;

}
