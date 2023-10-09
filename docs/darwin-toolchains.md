# Darwin (MacOS) toolchains

* `aarch64-darwin` - `aarch64-apple-darwin` target
* `x86_64-darwin` - `x86_64-apple-darwin` target

These toolchains use Nixpkgs cross-compilation packages, which
are not guaranteed to be cached, so building them might take a
long time. Binary cache is required to make it practical.
