{
  pkgs,
  mkLib,
}:
let
  inherit (pkgs) lib;

  targetRustFlags =
    flakeboxLib:
    ((flakeboxLib.mkStdTargets { }).default { }).args.CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS;

  defaultRustFlags = targetRustFlags (mkLib pkgs { });

  olderWildPkgs = pkgs // {
    wild = pkgs.wild.overrideAttrs (_: {
      version = "0.7.0";
    });
  };
  olderWildRustFlags = targetRustFlags (mkLib olderWildPkgs { });

  unversionedWildPkgs = pkgs // {
    wild = removeAttrs pkgs.wild [ "version" ];
  };
  unversionedWildRustFlags = targetRustFlags (mkLib unversionedWildPkgs { });

  gnuLdRustFlags = targetRustFlags (
    mkLib pkgs {
      config = {
        linker.wild.enable = false;
        linker.mold.enable = false;
      };
    }
  );
in
assert lib.assertMsg (
  lib.hasInfix "--ld-path=" defaultRustFlags
  && lib.hasInfix "--compress-debug-sections=zstd" defaultRustFlags
  && !(lib.hasInfix "--compress-debug-sections=zlib" defaultRustFlags)
) "Wild 0.9 and newer should compress debug sections with zstd";
assert lib.assertMsg (
  lib.hasInfix "--ld-path=" olderWildRustFlags
  && !(lib.hasInfix "--compress-debug-sections" olderWildRustFlags)
) "older Wild versions should remain selected without an unsupported compression flag";
assert lib.assertMsg (
  lib.hasInfix "--ld-path=" unversionedWildRustFlags
  && !(lib.hasInfix "--compress-debug-sections" unversionedWildRustFlags)
) "Wild packages without version metadata should remain selected without a compression flag";
assert lib.assertMsg (
  lib.hasInfix "--compress-debug-sections=zlib" gnuLdRustFlags
  && !(lib.hasInfix "--compress-debug-sections=zstd" gnuLdRustFlags)
  && !(lib.hasInfix "--ld-path=" gnuLdRustFlags)
) "fallback GNU ld should use broadly supported zlib debug compression";
pkgs.runCommand "linker-compatibility" { } ''
  touch "$out"
''
