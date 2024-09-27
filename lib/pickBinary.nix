{
  pkgs,
  system,
}:
# Create a package that contains only one `bin`ary from an input `pkg`
#
# For efficiency we built some binaries together (like fedimintd + fedimint-cli),
# but we would like to expose them separately.
{ pkg, bin }:
pkgs.stdenv.mkDerivation {
  inherit system;
  name = bin;

  dontUnpack = true;
  # just don't mess with it
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -a ${pkg}/bin/${bin} $out/bin/${bin}
  '';
}
