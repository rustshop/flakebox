{
  pkgs,
  crane,
  fenix,
  nixpkgs,
  android-nixpkgs,
}:
{
  modules ? [ ],
  config ? { },
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
        imports = lib.mapAttrsToList (name: type: ./modules/${name}) (
          lib.filterAttrs (name: type: lib.strings.hasSuffix ".nix" name) (builtins.readDir ./modules)
        );
      }
    ]
    ++ modules
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
  };

  optionsDocMd = pkgs.runCommand "options-doc.md" { } ''
    mkdir $out -p
    cat ${optionsDoc.optionsCommonMark} >> $out/options-doc.md
  '';
in
lib.makeScope pkgs.newScope (
  self:
  let
    inherit (self) callPackage;
  in
  {
    inherit pkgs;
    inherit
      crane
      fenix
      android-nixpkgs
      nixpkgs
      ;

    system = pkgs.stdenv.hostPlatform.system;

    config = finalConfig;

    docs = pkgs.stdenv.mkDerivation {
      name = "docs";
      src = ../docs;

      # Depend on the generated options reference used by the book.
      buildInputs = [ optionsDocMd ];

      # mdBook dependencies
      nativeBuildInputs = builtins.attrValues {
        inherit (pkgs) mdbook;
      };

      # Add the generated options reference to the source tree before building.
      buildPhase = ''
        rm -f ./nixos-options.md
        ln -s ${optionsDocMd}/options-doc.md "./nixos-options.md"
        mdbook build
      '';

      # copy the resulting output to the derivation's $out directory
      installPhase = ''
        mv book $out
      '';
    };

    root =
      let
        origRootdir = self.config.rootDirPackage;
      in
      pkgs.runCommand "flakebox-root-id-gen" { } ''
        cp -aL "${origRootdir}" $out
        chmod u+w $out/.config/flakebox

        ${pkgs.rblake2sum}/bin/rblake2sum $out | cut -d ' ' -f 1 > id
        mv id $out/.config/flakebox/
      '';

    craneMkLib = pkgs: self.enhanceCrane (self.config.craneMkLib pkgs);
    flakeboxLib = self;

    # wrapper over `mkShell` setting up flakebox env
    mkDevShell = callPackage ./mkDevShell.nix { };
    mkLintShell = callPackage ./mkLintShell.nix { };
    mkShells = callPackage ./mkShells.nix { };

    flakeboxBin = callPackage ./flakeboxBin.nix { };

    cargoCrap = callPackage ./pkgs/cargo-crap.nix { };

    source = callPackage ./source { };

    pickBinary = callPackage ./pickBinary.nix { };

    enhanceCrane = callPackage ./crane/enhance.nix { };
    mkFenixToolchain = callPackage ./mkFenixToolchain.nix { };
    mapWithToolchains' =
      f: toolchains:
      builtins.mapAttrs (
        toolchainName: toolchain:
        f toolchainName (toolchain.craneLib.overrideArgs { inherit toolchainName; })
      ) toolchains;
    mapWithToolchains = f: self.mapWithToolchains' (toochainName: craneLib: f craneLib);

    mkClangTarget = callPackage ./mkClangTarget.nix { };
    mkNativeTarget = callPackage ./mkNativeTarget.nix { };
    mkIOSTarget = callPackage ./mkIOSTarget.nix { };
    mkStdTargets = callPackage ./mkStdTargets.nix { };
    mkStdToolchains = callPackage ./mkStdToolchains.nix { };
    mkStdFenixToolchains = callPackage ./mkStdToolchains.nix { };
    craneMultiBuild = callPackage ./craneMultiBuild.nix { };
    universalLlvmConfig = callPackage ./universalLlvmConfig.nix { };

    defaultClang = if pkgs.stdenv.isDarwin then pkgs.llvmPackages.clang else pkgs.llvmPackages_18.clang;
    defaultLibClang =
      if pkgs.stdenv.isDarwin then pkgs.llvmPackages.libclang.lib else pkgs.llvmPackages_18.libclang.lib;
    defaultClangUnwrapped =
      if pkgs.stdenv.isDarwin then
        pkgs.llvmPackages.clang-unwrapped
      else
        pkgs.llvmPackages_18.clang-unwrapped;
    defaultStdenv = p: if pkgs.stdenv.isDarwin then pkgs.llvmPackages.stdenv else pkgs.stdenv;

    mkTarget = callPackage ./mkTarget.nix { };
    mkAndroidTarget = callPackage ./mkAndroidTarget.nix { };

    # older bindgen (clang-sys) crate can be told to use /usr/bin/clang this way
    targetLlvmConfigWrapper =
      {
        clangPkg,
        binClangPkg ? clangPkg,
        libClangPkg ? clangPkg,
      }:
      pkgs.writeShellScriptBin "llvm-config" ''
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

    mergeArgs =
      l: r:
      l
      // r
      // {
        buildInputs = (l.buildInputs or [ ]) ++ (r.buildInputs or [ ]);
        nativeBuildInputs = (l.nativeBuildInputs or [ ]) ++ (r.nativeBuildInputs or [ ]);
        packages = (l.packages or [ ]) ++ (r.packages or [ ]);
        env = (l.env or { }) // (r.env or { });
      };
  }
)
