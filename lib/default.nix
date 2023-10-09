{ pkgs, crane, fenix, android-nixpkgs }:
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
  inherit crane fenix android-nixpkgs;

  system = pkgs.system;

  config = finalConfig;

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

  root = let origRootdir = self.config.rootDirPackage; in
    pkgs.runCommand "flakebox-root-id-gen" { } ''
      cp -aL "${origRootdir}" $out
      chmod u+w $out/.config/flakebox

      ${pkgs.rblake2sum}/bin/rblake2sum $out | cut -d ' ' -f 1 > id
      mv id $out/.config/flakebox/
    '';

  craneLib = self.enhanceCrane self.config.craneLib.default;
  craneLibNightly = self.enhanceCrane self.config.craneLib.nightly;
  craneLibStable = self.enhanceCrane self.config.craneLib.stable;


  # wrapper over `mkShell` setting up flakebox env
  mkDevShell = callPackage ./mkDevShell.nix { };

  flakeboxBin = callPackage ./flakeboxBin.nix { };

  filter = callPackage ./filter { };

  filterSubPaths = self.filter.filterSubPaths;

  enhanceCrane = callPackage ./crane/enhance.nix { };
  mkFenixToolchain = callPackage ./mkFenixToolchain.nix { };
  mkAndroidToolchain = callPackage ./mkAndroidToolchain.nix { };
  mkIOSToolchain = callPackage ./mkIOSToolchain.nix { };
  mkFenixMultiToolchain = callPackage ./mkFenixMultiToolchain.nix { };
  mapWithToolchains' = f: toolchains: builtins.mapAttrs
    (toolchainName: toolchain: f toolchainName (toolchain.craneLib.overrideArgs { inherit toolchainName; }))
    toolchains;
  mapWithToolchains = f: self.mapWithToolchains' (toochainName: craneLib: f craneLib);

  mkStdFenixToolchains = callPackage ./mkStdFenixToolchains.nix { };
  craneMultiBuild = callPackage ./craneMultiBuild.nix { };
  universalLlvmConfig = callPackage ./universalLlvmConfig.nix { };

  # older bindgen (clang-sys) crate can be told to use /usr/bin/clang this way
  targetLlvmConfigWrapper = { clangPkg, binClangPkg ? clangPkg, libClangPkg ? clangPkg }: pkgs.writeShellScriptBin "llvm-config" ''
    if [ "$1" == "--bindir" ]; then
      echo "${binClangPkg}/bin"
      exit 0
    fi
    if [ "$1" == "--prefix" ]; then
      echo "${libClangPkg}"
      exit 0
    fi
    exec llvm-config "$@"
  '';

  mergeArgs = l: r: l // r // {
    buildInputs = l.buildInputs or [ ] ++ r.buildInputs or [ ];
    nativeBuildInputs = l.nativeBuildInputs or [ ] ++ r.nativeBuildInputs or [ ];
    packages = l.packages or [ ] ++ r.packages or [ ];
  };
})
