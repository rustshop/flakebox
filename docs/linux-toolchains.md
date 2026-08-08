# Linux toolchains

* `aarch64-linux` - `aarch64-unknown-linux-gnu` target
* `i686-linux` - `i686-unknown-linux-gnu` target
* `x86_64-linux` - `x86_64-unknown-linux-gnu` target

These toolchains become a no-op toolchains if the target
architecture is the same as native one.

These toolchains use Nixpkgs cross-compilation packages, which
are not guaranteed to be cached, so building them might take a
long time. Binary cache is required to make it practical.

Native Wild 0.9 and newer and mold linkers compress debug sections with
zstd. Flakebox omits debug compression for older Wild versions, which do
not support the compression option. When Flakebox uses GNU ld, including
for non-native targets, it asks the linker to use the more widely
available zlib format instead.

These toolchains don't work on MacOS right now (unimplemented in Nixpkgs).
