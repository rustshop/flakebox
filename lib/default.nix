{ pkgs, crane, fenix }:
{ modules ? [ ]
, config ? { }
,
}:
let
  lib = pkgs.lib;
  userConfig = config;

  evalModules = lib.evalModules {
    prefix = [ "config" ];
    specialArgs = {
      inherit fenix crane pkgs;
    };

    modules = [
      {
        imports =
          lib.mapAttrsToList
            (name: type: ./modules/${name})
            (lib.filterAttrs
              (name: type: lib.strings.hasSuffix ".nix" name)
              (builtins.readDir ./modules));
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
lib.makeScope pkgs.newScope (self:
let
  inherit (self) callPackage;
in
{
  inherit pkgs;
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

    doCheck = false;

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
        rm -f ./nixos-options.md
        ln -s ${optionsDocMd} "./nixos-options.md"
        # generate the site
        mdbook build
      '';

      # copy the resulting output to the derivation's $out directory
      installPhase = ''
        mv book $out
        # copy the md file so it's easy to update the checked-in version
        cp ./nixos-options.md $out/
      '';
    };

  share = self.config.shareDirPackage;

  inherit crane fenix;
  craneLib = self.enhanceCrane self.config.craneLib.default;
  craneLibNightly = self.enhanceCrane self.config.craneLib.nightly;
  craneLibStable = self.enhanceCrane self.config.craneLib.stable;


  # wrapper over `mkShell` setting up flakebox env
  mkDevShell = callPackage ./mkDevShell.nix { };

  flakeboxBin = callPackage ./flakeboxBin.nix { };

  filter = callPackage ./filter { };

  enhanceCrane = callPackage ./crane/enhance.nix { };
  mkFenixToolchain = callPackage ./mkFenixToolchain.nix { };
  mapWithToolchains = callPackage ./mapWithToolchains.nix { };
  stdCrossToolchains = callPackage ./stdCrossToolchains.nix { };
})
