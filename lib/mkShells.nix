{
  mkLintShell,
  mkDevShell,
  mkFenixToolchain,
  mkStdTargets,
  pkgs,
  lib,
  config,
}:
{
  channel ? config.toolchain.channel,
  components ? config.toolchain.components,

  targets ? lib.getAttrs [ "default" ] (mkStdTargets { }),
  toolchain ? mkFenixToolchain {
    inherit channel components targets;
  },

  crossTargets ? mkStdTargets { },
  crossToolchain ? mkFenixToolchain {
    inherit channel components;
    targets = crossTargets;
  },

  lintPackages ? [ ],
  ...
}@args:
let
  cleanedArgs = removeAttrs args [
    "channel"
    "components"
    "toolchain"
    "targets"
    "lintPackages"
    "crossToolchain"
    "crossTargets"
  ];
in
{
  lint = mkLintShell { packages = cleanedArgs.packages or [] ++ lintPackages; };
  default = mkDevShell (
    cleanedArgs
    // {
      inherit toolchain;
    }
  );

  cross = mkDevShell (
    cleanedArgs
    // {
      toolchain = crossToolchain;
    }
  );
}
