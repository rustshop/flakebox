{}:
f: toolchains:
builtins.mapAttrs
  (toolchainName: toolchain: f toolchainName (toolchain.craneLib.overrideArgs (prev: { inherit toolchainName; })))
  toolchains

