{}:
f: toolchains:
builtins.mapAttrs
  (toolchainName: toolchain: f toolchainName (toolchain.craneLib.overrideArgs ({ inherit toolchainName; })))
  toolchains

