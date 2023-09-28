{ crane
, enhanceCrane
, system
}:

f: toolchains:
builtins.mapAttrs
  (toolchainName: toolchain:
  let
    craneLib = enhanceCrane (crane.lib.${system}.overrideToolchain toolchain.toolchain);
  in
  f toolchainName
    (craneLib.overrideScope'
      (self: prev: {
        args = prev.args // (toolchain.args or { }) // {
          preBuild = toolchain.envs + (prev.args.preBuild or "");
          toolchain = toolchainName;
        };
      })))
  toolchains

