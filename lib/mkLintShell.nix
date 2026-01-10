{
  pkgs,
  config,
  docs,
  mkFenixToolchain,
  lib,
  mergeArgs,
  mkStdTargets,
}:
let
  rustfmt = config.toolchain.rustfmt;
in

{
  packages ? [ ],
  stdenv ? pkgs.stdenv,
  targets ? lib.getAttrs [ "default" ] (mkStdTargets { }),
  toolchain ? mkFenixToolchain {
    inherit targets stdenv;
    channel = config.toolchain.channel;
    components = config.toolchain.components;
    isLintShell = true;
  },
  ...
}@args:
let
  cleanedArgs = removeAttrs args [
    "toolchain"
    "packages"
  ];
in
let
  baseStdenv =
    if lib.isFunction toolchain.stdenv then
      toolchain.stdenv pkgs
    else if toolchain ? stdenv then
      toolchain.stdenv
    else if lib.isFunction stdenv then
      stdenv pkgs
    else
      stdenv;

  mkShell = pkgs.mkShell.override {
    stdenv =
      if baseStdenv.isLinux && config.linker.wild.enable && pkgs ? useWildLinker then
        pkgs.useWildLinker baseStdenv
      else if pkgs.stdenv.isLinux && config.linker.mold.enable && pkgs.stdenvAdapters ? useMoldLinker then
        pkgs.stdenvAdapters.useMoldLinker baseStdenv
      else
        baseStdenv;
  };
  args = cleanedArgs // {
    packages =
      packages
      ++ [
        toolchain.toolchain
        rustfmt
      ]
      ++ config.env.shellPackages
      ++ (builtins.attrValues {
        # Core & generic
        inherit (pkgs)
          git
          coreutils
          parallel
          shellcheck
          ;
        # Nix
        inherit (pkgs) nixfmt-rfc-style;
        # TODO: make conditional on `config.just.enable`
        inherit (pkgs) just;
      });

    shellHook = ''
      # set the root dir
      git_root="$(git rev-parse --show-toplevel)"
      export FLAKEBOX_PROJECT_ROOT_DIR="''${git_root:-$PWD}"
      export PATH="''${git_root}/.config/flakebox/bin/:''${PATH}"
    '';
  };
in
mkShell (mergeArgs toolchain.shellArgs args)
