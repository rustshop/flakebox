{ pkgs, flakeboxLib }:
let
  target = "aarch64-unknown-linux-gnu";
  targetPrefix = "aarch64-unknown-linux-gnu-";
  toolchains = flakeboxLib.mkStdFenixToolchains { };
  crossToolchain = toolchains.aarch64-linux;
  args = flakeboxLib.mergeArgs toolchains.default.commonArgs crossToolchain.commonArgs;
in
pkgs.runCommand "aarch64-cross-linker-compression"
  (
    args
    // {
      nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ crossToolchain.toolchain ];
    }
  )
  ''
    export CARGO_HOME="$TMPDIR/cargo-home"
    mkdir -p src

    cat > Cargo.toml <<'EOF'
    [package]
    name = "cross-linker-compression-check"
    version = "0.0.0"
    edition = "2024"
    EOF

    cat > src/main.rs <<'EOF'
    fn main() {
        println!("cross-linker compression check");
    }
    EOF

    cargo build --offline --target ${target}
    cargo build --offline

    linker_dir="$(dirname "$CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER")"
    linker="$linker_dir/${targetPrefix}ld"
    cross_binary="target/${target}/debug/cross-linker-compression-check"
    native_binary="target/debug/cross-linker-compression-check"

    "$linker" --version | grep -F "GNU ld"
    case "$CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS" in
      *"-fuse-ld=$linker"*"--compress-debug-sections=zlib"*) ;;
      *)
        echo "AArch64 Rust flags do not select the tested linker and compression policy" >&2
        exit 1
        ;;
    esac
    "$linker" --compress-debug-sections=zlib --version >/dev/null
    "$linker_dir/${targetPrefix}readelf" -h "$cross_binary" | grep -F "Machine:" | grep -F "AArch64"
    "$linker_dir/${targetPrefix}readelf" -SW "$cross_binary" | grep -E '\.debug_info.* C '

    native_linker="$(
      printf '%s\n' "$CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS" \
        | sed -n 's/.*--ld-path=\([^ ]*\).*/\1/p'
    )"
    case "$CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS" in
      *"--ld-path=$native_linker"*"--compress-debug-sections=zstd"*) ;;
      *)
        echo "native Rust flags do not preserve the Wild and zstd policy" >&2
        exit 1
        ;;
    esac
    "$native_linker" --version | grep -F "Wild"
    "$native_linker" --compress-debug-sections=zstd --version >/dev/null
    ${pkgs.binutils}/bin/readelf -h "$native_binary" | grep -F "Machine:" | grep -F "Advanced Micro Devices X86-64"
    ${pkgs.binutils}/bin/readelf -SW "$native_binary" | grep -E '\.debug_info.* C '

    touch "$out"
  ''
