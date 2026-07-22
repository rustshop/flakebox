{ pkgs, flakeboxLib }:
let
  inherit (pkgs) lib;

  assertEq =
    name: actual: expected:
    lib.assertMsg (
      actual == expected
    ) "${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  stdToolchains = flakeboxLib.mkStdToolchains { };
  isLinux = pkgs.stdenv.isLinux;
  hasAndroid = stdToolchains ? aarch64-android;
  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;

  roleToolchains = {
    inherit (stdToolchains) default;
  }
  // lib.optionalAttrs isLinux {
    inherit (stdToolchains) aarch64-linux;
  };
  roleOutputs =
    (flakeboxLib.craneMultiBuild {
      profiles = [
        "dev"
        "release"
      ];
      toolchains = roleToolchains;
      argsFor =
        {
          capabilities,
          toolchainName,
          packages,
        }:
        {
          resolvedForCell = toolchainName;
          resolvedTargetCapability = capabilities.targetBuildInputs;
          resolvedBuildInput = packages.buildInputs.openssl;
          resolvedNativeBuildInput = packages.nativeBuildInputs.pkg-config;
          resolvedDepsBuildBuild = packages.depsBuildBuild.hello;
        };
    })
      (craneLib: {
        probe = {
          inherit (craneLib.args)
            resolvedBuildInput
            resolvedDepsBuildBuild
            resolvedForCell
            resolvedNativeBuildInput
            resolvedTargetCapability
            ;
          profile = craneLib.cargoProfile;
        };
      });

  customToolchains.default = builtins.removeAttrs stdToolchains.default [ "dependencyContext" ];
  customWithoutRoleAccess =
    (flakeboxLib.craneMultiBuild {
      toolchains = customToolchains;
      profiles = [ "dev" ];
      argsFor = { toolchainName, ... }: {
        resolvedForCell = toolchainName;
      };
    })
      (craneLib: {
        probe = craneLib.args.resolvedForCell;
      });
  customWithRoleAccess = builtins.tryEval (
    let
      outputs =
        (flakeboxLib.craneMultiBuild {
          toolchains = customToolchains;
          profiles = [ "dev" ];
          argsFor = { packages, ... }: {
            resolvedBuildInput = packages.buildInputs.openssl;
          };
        })
          (craneLib: {
            probe = craneLib.args.resolvedBuildInput;
          });
    in
    builtins.seq outputs.probe true
  );

  unsupportedToolchainNames = [
    "wasm32-unknown"
  ]
  ++ lib.optionals hasAndroid [
    "aarch64-android"
  ];
  unsupportedToolchains = lib.getAttrs (
    [
      "default"
    ]
    ++ unsupportedToolchainNames
  ) stdToolchains;
  capabilityOutputs =
    (flakeboxLib.craneMultiBuild {
      toolchains = unsupportedToolchains;
      profiles = [ "dev" ];
      argsFor =
        {
          capabilities,
          packages,
          ...
        }:
        {
          resolvedTargetCapability = capabilities.targetBuildInputs;
          resolvedOptionalBuildInput =
            if capabilities.targetBuildInputs then packages.buildInputs.openssl else null;
        };
    })
      (craneLib: {
        probe = {
          inherit (craneLib.args) resolvedOptionalBuildInput resolvedTargetCapability;
        };
      });

  unsupportedRoleAccess =
    toolchainName:
    let
      toolchain = stdToolchains.${toolchainName};
      context = toolchain.dependencyContext;
      outputs =
        (flakeboxLib.craneMultiBuild {
          toolchains = {
            inherit (stdToolchains) default;
            ${toolchainName} = toolchain;
          };
          profiles = [ "dev" ];
          argsFor = { packages, ... }: {
            resolvedBuildInput = packages.buildInputs.openssl;
          };
        })
          (craneLib: {
            probe = craneLib.args.resolvedBuildInput;
          });
    in
    assert context ? packages;
    assert !(context.packages ? buildInputs);
    builtins.tryEval (builtins.seq outputs.${toolchainName}.dev.probe true);

  precedenceToolchains.default = stdToolchains.default // {
    craneLib = stdToolchains.default.craneLib.overrideArgs {
      precedenceProbe = "built-in";
    };
  };
  precedenceOutputs =
    (flakeboxLib.craneMultiBuild {
      toolchains = precedenceToolchains;
      profiles = [ "dev" ];
      argsFor = _: {
        precedenceProbe = "argsFor";
      };
    })
      (craneLib: {
        precedenceProbe = {
          afterArgsFor = craneLib.args.precedenceProbe;
          directCall =
            (craneLib.mkCargoDerivation {
              pname = "crane-multi-build-precedence-probe";
              version = "0";
              src = pkgs.emptyDirectory;
              cargoArtifacts = null;
              buildPhaseCargoCommand = "true";
              precedenceProbe = "direct-call";
            }).precedenceProbe;
        };
      });

  assertions = [
    (assertEq "native buildInputs role" (toString roleOutputs.probe.resolvedBuildInput) (
      toString pkgs.pkgsHostTarget.openssl
    ))
    (assertEq "native nativeBuildInputs role" (toString roleOutputs.probe.resolvedNativeBuildInput) (
      toString pkgs.pkgsBuildHost.pkg-config
    ))
    (assertEq "native depsBuildBuild role" (toString roleOutputs.probe.resolvedDepsBuildBuild) (
      toString pkgs.pkgsBuildBuild.hello
    ))
    (assertEq "native target capability" roleOutputs.probe.resolvedTargetCapability true)
    (assertEq "argsFor native cell" roleOutputs.probe.resolvedForCell "default")
    (assertEq "argsFor value reused for dev profile" roleOutputs.dev.probe.resolvedForCell "default")
    (assertEq "argsFor value reused for release profile" roleOutputs.release.probe.resolvedForCell
      "default"
    )
    (assertEq "dev profile remains independent" roleOutputs.dev.probe.profile "dev")
    (assertEq "release profile remains independent" roleOutputs.release.probe.profile "release")
    (assertEq "custom toolchain without role access" customWithoutRoleAccess.probe "default")
    (assertEq "custom toolchain role access fails lazily" customWithRoleAccess.success false)
    (assertEq "wasm32 target capability"
      capabilityOutputs.wasm32-unknown.dev.probe.resolvedTargetCapability
      false
    )
    (assertEq "wasm32 capability filters target input"
      capabilityOutputs.wasm32-unknown.dev.probe.resolvedOptionalBuildInput
      null
    )
    (assertEq "wasm32-unknown-unknown target input fails"
      (unsupportedRoleAccess "wasm32-unknown").success
      false
    )
    (assertEq "built-in to argsFor precedence" precedenceOutputs.precedenceProbe.afterArgsFor "argsFor")
    (assertEq "argsFor to direct-call precedence" precedenceOutputs.precedenceProbe.directCall
      "direct-call"
    )
  ]
  ++ lib.optionals isLinux [
    (assertEq "AArch64 buildInputs role"
      (toString roleOutputs.aarch64-linux.dev.probe.resolvedBuildInput)
      (toString crossPkgs.pkgsHostTarget.openssl)
    )
    (assertEq "AArch64 nativeBuildInputs role"
      (toString roleOutputs.aarch64-linux.dev.probe.resolvedNativeBuildInput)
      (toString crossPkgs.pkgsBuildHost.pkg-config)
    )
    (assertEq "AArch64 depsBuildBuild role"
      (toString roleOutputs.aarch64-linux.dev.probe.resolvedDepsBuildBuild)
      (toString crossPkgs.pkgsBuildBuild.hello)
    )
    (assertEq "AArch64 target capability" roleOutputs.aarch64-linux.dev.probe.resolvedTargetCapability
      true
    )
    (assertEq "argsFor cross cell" roleOutputs.aarch64-linux.dev.probe.resolvedForCell "aarch64-linux")
  ]
  ++ lib.optionals hasAndroid [
    (assertEq "Android target capability"
      capabilityOutputs.aarch64-android.dev.probe.resolvedTargetCapability
      false
    )
    (assertEq "Android capability filters target input"
      capabilityOutputs.aarch64-android.dev.probe.resolvedOptionalBuildInput
      null
    )
    (assertEq "Android target input fails" (unsupportedRoleAccess "aarch64-android").success false)
  ];
in
assert lib.all (assertion: assertion) assertions;
pkgs.runCommand "crane-multi-build-tests"
  {
    nativeBuildInputs = [ (lib.getBin pkgs.nix) ];
  }
  ''
    fixture=${./crane-multi-build-eval-fixture.nix}
    crane_multi_build=${../lib/craneMultiBuild.nix}
    nixpkgs_lib=${pkgs.path}/lib

    # Give the nested evaluator writable state without connecting to the host
    # daemon. It only evaluates the self-contained expression above.
    export HOME="$TMPDIR/home"
    export NIX_STATE_DIR="$TMPDIR/nix-state"
    export NIX_LOG_DIR="$TMPDIR/nix-log"
    export NIX_CONF_DIR="$TMPDIR/nix-conf"
    mkdir -p "$HOME" "$NIX_CONF_DIR"

    eval_scenario() {
      local scenario=$1
      nix-instantiate --eval --strict --expr \
        "import $fixture {
          craneMultiBuildPath = $crane_multi_build;
          nixpkgsLibPath = $nixpkgs_lib;
          scenario = \"$scenario\";
        }"
    }

    if ! eval_scenario scope >/dev/null 2>scope-trace; then
      cat scope-trace >&2
      exit 1
    fi

    test "$(grep -Fc 'argsFor invocation: default' scope-trace)" -eq 1
    test "$(grep -Fc 'argsFor invocation: cross' scope-trace)" -eq 1

    check_diagnostic() {
      local scenario=$1
      local cell=$2

      if eval_scenario "$scenario" >"$scenario-out" 2>"$scenario-err"; then
        echo "expected $scenario evaluation to fail" >&2
        exit 1
      fi

      grep -Fq "toolchain/cell \`$cell\` cannot provide \`packages.buildInputs\`" "$scenario-err"
    }

    check_diagnostic custom custom
    check_diagnostic wasm wasm32-unknown
    check_diagnostic android aarch64-android

    touch "$out"
  ''
