{ pkgs, flakeboxLib }:
let
  inherit (pkgs) lib;

  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
  expectedPkgConfig = crossPkgs.pkgsBuildHost.pkg-config;
  expectedOpenSsl = crossPkgs.pkgsHostTarget.openssl;
  targetOpenSsl = lib.getLib expectedOpenSsl;
  toolchains = lib.getAttrs [
    "default"
    "aarch64-linux"
  ] (flakeboxLib.mkStdToolchains { });

  outputs =
    (flakeboxLib.craneMultiBuild {
      inherit toolchains;
      profiles = [ "release" ];
      argsFor =
        {
          packages,
          toolchainName,
          ...
        }:
        lib.optionalAttrs (toolchainName == "aarch64-linux") (
          assert toString packages.nativeBuildInputs.pkg-config == toString expectedPkgConfig;
          assert toString packages.buildInputs.openssl == toString expectedOpenSsl;
          {
            buildInputs = [ packages.buildInputs.openssl ];
            nativeBuildInputs = [ packages.nativeBuildInputs.pkg-config ];
          }
        );
    })
      (craneLib: {
        package = craneLib.buildPackage {
          pname = "cell-aware-cross-inputs";
          version = "0.1.0";
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;
        };
      });

  crossPackage = outputs.aarch64-linux.release.package;
in
pkgs.runCommand "cell-aware-cross-inputs-check"
  {
    nativeBuildInputs = [
      pkgs.binutils
      pkgs.file
    ];
  }
  ''
    binary=${crossPackage}/bin/cell-aware-cross-inputs
    ${expectedPkgConfig}/bin/aarch64-unknown-linux-gnu-pkg-config --version > pkg-config-version.txt
    file "$binary" > binary-file.txt
    readelf -h "$binary" > binary-elf-header.txt
    readelf -d "$binary" > binary-dynamic.txt

    grep -Fq "ELF 64-bit LSB pie executable, ARM aarch64" binary-file.txt
    grep -Eq "Machine:[[:space:]]+AArch64" binary-elf-header.txt
    grep -Eq "Shared library: \\[libssl\\.so" binary-dynamic.txt
    grep -F "(RUNPATH)" binary-dynamic.txt > binary-runpath.txt
    grep -Fq "${targetOpenSsl}/lib" binary-runpath.txt

    target_libssl=$(readlink -f ${targetOpenSsl}/lib/libssl.so)
    file "$target_libssl" > dependency-file.txt
    readelf -h "$target_libssl" > dependency-elf-header.txt

    grep -Fq "ELF 64-bit LSB shared object, ARM aarch64" dependency-file.txt
    grep -Eq "Machine:[[:space:]]+AArch64" dependency-elf-header.txt

    mkdir "$out"
    cp ./*.txt "$out/"
  ''
