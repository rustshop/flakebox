{ pkgs, crane, fenix }:
{ modules ? [ ]
, config ? { }
,
}:
let
  lib = pkgs.lib;
  userConfig = config;

  evalModules = pkgs.lib.evalModules {
    prefix = [ "config" ];
    specialArgs = {
      inherit fenix crane pkgs;
    };

    modules = [
      {
        imports = [
          # TODO: readDir
          ./modules/toolchain.nix
          ./modules/crane.nix
          ./modules/git.nix
          ./modules/shareDir.nix
        ];
      }
    ] ++
    modules
    ++ [
      {
        config = userConfig;
      }
    ];
  };
  finalConfig = evalModules.config;

  optionsDoc = pkgs.nixosOptionsDoc {
    inherit (evalModules) options;
    documentType = "none";
    allowDocBook = false;
    markdownByDefault = true;
  };

  optionsDocMd =
    pkgs.runCommand "options-doc.md" { } ''
      cat ${optionsDoc.optionsCommonMark} >> $out
    '';

in
pkgs.lib.makeScope pkgs.newScope (self:
let
  inherit (self) callPackage;
in
{
  system = pkgs.system;

  config = finalConfig;

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

  docs =
    pkgs.stdenv.mkDerivation {
      name = "docs";
      src = ../docs;

      # depend on our options doc derivation
      buildInput = [ optionsDocMd ];

      # mkdocs dependencies
      nativeBuildInputs = builtins.attrValues {
        inherit (pkgs) mdbook;
      };

      # symlink our generated docs into the correct folder before generating
      buildPhase = ''
        ln -s ${optionsDocMd} "./nixos-options.md"
        # generate the site
        mdbook build
      '';

      # copy the resulting output to the derivation's $out directory
      installPhase = ''
        mv book $out
      '';
    };

  share = self.config.shareDirPackage;

  craneLib = self.config.craneLib.default;
  craneLibNightly = self.config.craneLib.nightly;
  craneLibStable = self.config.craneLib.stable;



  # wrapper over `mkShell` setting up flakebox env
  mkDevShell = callPackage ./mkDevShell.nix { };

  flakeboxBin = callPackage ./flakeboxBin.nix { };

  filter = callPackage ./filter { };
  ci = callPackage ./ci { };
})
