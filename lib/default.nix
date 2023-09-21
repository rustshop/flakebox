{ pkgs, crane, fenix }:
{ modules ? [ ]
, config ? { }
,
}:
let
  lib = pkgs.lib;
  userConfig = config;
in
pkgs.lib.makeScope pkgs.newScope (self:
let
  inherit (self) callPackage;
  system = pkgs.system;

  evalModulesRes = pkgs.lib.evalModules {
    specialArgs = {
      inherit fenix crane pkgs;
    };

    modules = [
      {
        imports = [ ./toolchain.nix ];
      }
    ] ++
    modules
    ++ [
      {
        config = userConfig;
      }
    ];
  };
  config = evalModulesRes.config;


  pathToDerivation = src:
    let
      builderScript = pkgs.writeScript "copy-path.sh" ''
        cp -rT $src $out
      '';
    in
    derivation {
      name = "copy-path-derivation";
      builder = "${pkgs.bash}/bin/bash";
      args = [ builderScript ];
      system = pkgs.system;
      inherit src;
      PATH = with pkgs;
        lib.makeBinPath [ coreutils ];
    };
in
{
  # package containing all the Rust/cargo toolchain binaries to import in the dev shells and use by default
  toolchain = config.toolchain.default;

  # package containing rust-analyzer to import into dev shell
  rust-analyzer = pkgs.rust-analyzer;

  # package containing rustfmt  to import into dev shell (by default nightly rustfmt, as it supports lots of handy directives)
  rustfmt = config.toolchain.rustfmt;

  # craneLib from `crane` package - for building Rust packages with Nix
  craneLib = crane.lib.${system}.overrideToolchain config.toolchain.default;

  # common args for crane, used for building internal Rust binaries
  # not meant to be modified as part of downstream customizations
  cranePrivateCommonArgs = {
    pname = "flakebox";

    src = builtins.path {
      name = "flakebox";
      path = ../.;
    };

    nativeBuildInputs = [ pkgs.mold ];

    installCargoArtifactsMode = "use-zstd";
  };

  # flakebox files available to `flakebox` tool
  share = pathToDerivation ../share;

  # wrapper over `mkShell` setting up flakebox env
  mkDevShell = callPackage ./mkDevShell.nix { };

  flakeboxBin = callPackage ./flakeboxBin.nix { };

  filter = callPackage ./filter { };
  ci = callPackage ./ci { };
})
