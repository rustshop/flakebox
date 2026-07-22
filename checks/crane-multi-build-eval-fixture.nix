# `builtins.tryEval` discards error text, and pure Nix evaluation cannot expose
# how often it forced a function. This minimal Crane-shaped adapter exists only
# so the check can capture those two `craneMultiBuild` contracts from a nested
# evaluator. All package-role and merge behavior uses the real Crane library in
# `crane-multi-build-tests.nix`; do not reproduce it here.
{
  craneMultiBuildPath,
  nixpkgsLibPath,
  scenario,
}:
let
  lib = import nixpkgsLibPath;

  mkCraneLib = args: {
    inherit args;
    overrideArgs = newArgs: mkCraneLib (args // newArgs);
    mapWithProfiles = outputsFn: profiles: lib.genAttrs profiles (_: outputsFn (mkCraneLib args));
  };

  baseToolchain = {
    craneLib = mkCraneLib { };
  };
  unsupportedToolchain =
    cellKind:
    baseToolchain
    // {
      dependencyContext = {
        packages.depsBuildBuild = { };
        unavailablePackages.buildInputs = "this ${cellKind} cell has no truthful target Nixpkgs package universe";
      };
    };

  craneMultiBuild = import craneMultiBuildPath {
    craneMkLib = _: throw "unused craneMkLib";
    mkStdToolchains = _: throw "unused mkStdToolchains";
    inherit lib;
    pkgs = { };
  };

  cell =
    if scenario == "custom" then
      "custom"
    else if scenario == "wasm" then
      "wasm32-unknown"
    else
      "aarch64-android";
  cellToolchain =
    if scenario == "custom" then
      baseToolchain
    else if scenario == "wasm" then
      unsupportedToolchain "wasm32-unknown-unknown"
    else
      unsupportedToolchain "Android";

  outputs =
    (craneMultiBuild {
      profiles = [
        "dev"
        "release"
      ];
      toolchains = {
        default = baseToolchain;
        ${if scenario == "scope" then "cross" else cell} =
          if scenario == "scope" then baseToolchain else cellToolchain;
      };
      argsFor =
        { toolchainName, packages, ... }:
        if scenario == "scope" then
          builtins.trace "argsFor invocation: ${toolchainName}" {
            marker = toolchainName;
          }
        else
          {
            marker = packages.buildInputs.openssl;
          };
    })
      (craneLib: {
        probe = craneLib.args.marker;
      });
in
if scenario == "scope" then
  builtins.deepSeq outputs true
else
  builtins.seq outputs.${cell}.dev.probe true
