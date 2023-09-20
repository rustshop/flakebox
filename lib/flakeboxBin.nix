{ pkgs
, craneLib
, cranePrivateCommonArgs
}:
craneLib.buildPackage (cranePrivateCommonArgs // {
  name = "flakebox";
  cargoExtraArgs = "--locked -p flakebox";

})
