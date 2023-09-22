{ cranePrivateCommonArgs
, filter
, craneLib
}:
craneLib.buildPackage (cranePrivateCommonArgs // {
  src = filter.filterSubdirs {
    root = cranePrivateCommonArgs.src;
    dirs = [
      "Cargo.toml"
      "Cargo.lock"
      ".cargo"
      "flakebox-bin"
    ];
  };

  name = "flakebox";
  cargoExtraArgs = "--locked -p flakebox";
})
