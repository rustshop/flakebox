{ cranePrivateCommonArgs
, filterSubPaths
, craneLib
}:
let
  src = filterSubPaths {
    root = cranePrivateCommonArgs.src;
    paths = [
      "Cargo.toml"
      "Cargo.lock"
      ".cargo"
      "flakebox-bin"
    ];
  };

  craneArgs = (cranePrivateCommonArgs // {
    inherit src;

    pname = "flakebox";
    cargoExtraArgs = "--locked -p flakebox";
  });

  deps =
    craneLib.buildDepsOnly craneArgs;
in
craneLib.buildPackage (craneArgs // {
  cargoArtifacts = deps;
})
