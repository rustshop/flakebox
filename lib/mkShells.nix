{ mkLintShell
, mkDevShell
, mkStdFenixToolchains
, mkFenixMultiToolchain
, pkgs
}:
{ lintPackages ? [ ]
, toolchains ? [
    "default"
    "aarch64-android"
    "i686-android"
    "x86_64-android"
    "arm-android"
  ]
, ...
} @ args:
let
  cleanedArgs = removeAttrs args [ "lintPackages" "toolchains" ];
in
{
  lint = mkLintShell { packages = lintPackages; };
  default = mkDevShell cleanedArgs;

  cross = mkDevShell {
    packages = [ ];
    toolchain = mkFenixMultiToolchain {
      toolchains = pkgs.lib.getAttrs toolchains
        (mkStdFenixToolchains { });
    };
  };
}
