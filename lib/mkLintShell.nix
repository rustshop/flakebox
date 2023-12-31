{ pkgs
, config
, docs
, mkFenixToolchain
, lib
, mergeArgs
}:
let
  defaultToolchain = config.toolchain.default;
  rustfmt = config.toolchain.rustfmt;
in

{ packages ? [ ]
, stdenv ? pkgs.stdenv
, toolchain ? mkFenixToolchain { toolchain = defaultToolchain; isLintShell = true; inherit stdenv; }
, ...
} @ args:
let
  cleanedArgs = removeAttrs args [
    "toolchain"
    "packages"
  ];
in
let
  mkShell =
    if toolchain ? stdenv then
      pkgs.mkShell.override { stdenv = toolchain.stdenv; }
    else
      pkgs.mkShell;
  args = cleanedArgs // {
    packages =
      packages ++ [
        toolchain.toolchain
        rustfmt
      ] ++ config.env.shellPackages ++ (builtins.attrValues {
        # Core & generic
        inherit (pkgs) git coreutils parallel shellcheck;
        # Nix
        inherit (pkgs) nixpkgs-fmt;
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
mkShell (
  mergeArgs toolchain.shellArgs args
)
