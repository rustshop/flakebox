{
  pkgs,
  system,
}:
# Create a package that contains only one `bin`ary(ies) from an input `pkg`
#
# `bin` must be set, and it will be used as a name of the new package
{
  pkg,
  name ? null,
  bin ? null,
  bins ? [ ],
}:
pkgs.stdenv.mkDerivation {
  inherit system;
  name = if name != null then name else bin;
  pname = if name != null then name else bin;

  dontUnpack = true;
  # just don't mess with it
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin
    ${if bin != null then "cp -a ${pkg}/bin/${bin} $out/bin/${bin}" else ""}
    ${builtins.concatStringsSep "\n" (map (b: "cp -a ${pkg}/bin/${b} $out/bin/${b}") bins)}
  '';
}
