{ cranePrivateCommonArgs
, filter
, craneLib
}:
let
  src = filter.filterSubdirs {
    root = cranePrivateCommonArgs.src;
    dirs = [
      "Cargo.toml"
      "Cargo.lock"
      ".cargo"
      "flakebox-bin"
    ];
  };

  craneArgs = (cranePrivateCommonArgs // {
    inherit src;

    name = "flakebox";
    cargoExtraArgs = "--locked -p flakebox";
  });

  deps =
    craneLib.buildDepsOnly craneArgs;
in
craneLib.buildPackage (craneArgs // {
  cargoArtifacts = deps;
})
