{ pkgs, ... }:
let lib = pkgs.lib; in craneLib:
craneLib.overrideScope' (self: prev: {
  cargoProfile = "release";
  args = {
    # https://github.com/ipetkov/crane/issues/76#issuecomment-1296025495
    installCargoArtifactsMode = "use-zstd";
  };

  mkCargoDerivation = args: prev.mkCargoDerivation
    (
      { CARGO_PROFILE = self.cargoProfile; }
      // self.args // args
    );

  # functions that don't lower to `mkCargoDerivation` or lower too late it requires `args.src`
  buildDepsOnly = args: prev.buildDepsOnly (self.args // args);
  crateNameFromCargoToml = args: prev.crateNameFromCargoToml (self.args // args);
  mkDummySrc = args: prev.mkDummySrc (self.args // args);
  vendorCargoDeps = args: prev.vendorCargoDeps (self.args // args);

  buildWorkspaceDepsOnly = origArgs:
    let
      args = builtins.removeAttrs origArgs [ "pname" ];
      pname = if builtins.hasAttr "pname" origArgs then "${origArgs.pname}-workspace" else if builtins.hasAttr "pname" self.args then "${self.args.pname}-workspace" else null;
    in
    self.buildDepsOnly
      (self.args // (lib.optionalAttrs (pname != null) {
        inherit pname;
      }) // {
        buildPhaseCargoCommand = "cargoWithProfile doc --workspace --locked ; cargoWithProfile check --workspace --all-targets --locked ; cargoWithProfile build --locked --workspace --all-targets";
        doCheck = false;
      } // args);

  buildWorkspace = origArgs:
    let
      args = builtins.removeAttrs origArgs [ "pname" ];
      pname = if builtins.hasAttr "pname" origArgs then "${origArgs.pname}-workspace" else if builtins.hasAttr "pname" self.args then "${self.args.pname}-workspace" else null;
    in
    self.mkCargoDerivation (
      (self.args // (lib.optionalAttrs (pname != null) {
        inherit pname;
      }) // {
        buildPhaseCargoCommand = "cargoWithProfile doc --workspace --locked ; cargoWithProfile check --workspace --all-targets --locked ; cargoWithProfile build --locked --workspace --all-targets";
        doCheck = false;
      } // args)
    );

  buildCommand = origArgs: self.mkCargoDerivation (
    let
      args = builtins.removeAttrs origArgs [ "cmd" "buildPhaseCargoCommand" ];
    in
    ({
      pname = if builtins.hasAttr "pname" origArgs then "${origArgs.pname}-cmd" else if builtins.hasAttr "pname" self.args then "${self.args.pname}-cmd" else null;
      buildPhaseCargoCommand = origArgs.cmd;
      doCheck = false;
    } // args)
  );

  mapWithProfiles = f: profiles: builtins.listToAttrs (builtins.map (cargoProfile: { name = cargoProfile; value = f (self.overrideScope' (self: prev: { inherit cargoProfile; })); }) profiles);
})
