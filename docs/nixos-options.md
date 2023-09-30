## config\.cargo\.pre-commit\.cargo-fmt\.enable

Whether to enable cargo fmt check in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/cargo\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/cargo.nix)



## config\.cargo\.pre-commit\.cargo-lock\.enable



Whether to enable cargo lock check in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/cargo\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/cargo.nix)



## config\.convco\.enable



Whether to enable convco integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/convco\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/convco.nix)



## config\.convco\.commit-msg\.enable



Whether to enable convco git commit-msg hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/convco\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/convco.nix)



## config\.craneLib\.default



craneLib to use by default

Default value is craneLib initialized with ` config.toolchain.default `



*Type:*
attribute set



*Default:*

```
{
  appendCrateRegistries = <function>;
  buildDepsOnly = <function, args: {cargoBuildCommand?, cargoCheckCommand?, cargoExtraArgs?, cargoTestCommand?, cargoTestExtraArgs?}>;
  buildPackage = <function, args: {cargoBuildCommand?, cargoExtraArgs?, cargoTestCommand?, cargoTestExtraArgs?}>;
  buildTrunkPackage = <function, args: {trunkExtraArgs?, trunkExtraBuildArgs?, trunkIndexPath?}>;
  callPackage = <function>;
  cargo = <derivation rust-stable-with-components-2023-08-24>;
  cargoAudit = <function, args: {advisory-db, cargoAuditExtraArgs?, cargoExtraArgs?, src}>;
  cargoBuild = <function, args: {cargoArtifacts, cargoExtraArgs?}>;
  cargoClippy = <function, args: {cargoArtifacts, cargoClippyExtraArgs?, cargoExtraArgs?}>;
  cargoDoc = <function, args: {cargoDocExtraArgs?, cargoExtraArgs?}>;
  cargoFmt = <function, args: {cargoExtraArgs?, rustFmtExtraArgs?}>;
  cargoHelperFunctionsHook = <derivation cargoHelperFunctionsHook>;
  cargoLlvmCov = <function, args: {cargoExtraArgs?, cargoLlvmCovCommand?, cargoLlvmCovExtraArgs?}>;
  cargoNextest = <function, args: {cargoArtifacts, cargoExtraArgs?, cargoNextestExtraArgs?, doInstallCargoArtifacts?, partitionType?, partitions?}>;
  cargoTarpaulin = <function, args: {cargoExtraArgs?, cargoTarpaulinExtraArgs?}>;
  cargoTest = <function, args: {cargoArtifacts, cargoExtraArgs?, cargoTestExtraArgs?}>;
  cleanCargoSource = <function>;
  cleanCargoToml = <function, args: {cargoToml?, cargoTomlContents?}>;
  clippy = <derivation rust-stable-with-components-2023-08-24>;
  configureCargoCommonVarsHook = <derivation configureCargoCommonVarsHook>;
  configureCargoVendoredDepsHook = <derivation configureCargoVendoredDepsHook>;
  craneUtils = <derivation crane-utils-0.1.0>;
  crateNameFromCargoToml = <function>;
  crateRegistries = {
    "registry+https://github.com/rust-lang/crates.io-index" = {
      downloadUrl = "https://crates.io/api/v1/crates/{crate}/{version}/download";
      fetchurlExtraArgs = { };
    };
  };
  devShell = <function, args: {checks?, inputsFrom?, packages?}>;
  downloadCargoPackage = <function, args: {checksum, name, version}>;
  downloadCargoPackageFromGit = <function, args: {allRefs?, git, ref?, rev}>;
  filterCargoSources = <function>;
  findCargoFiles = <function>;
  inheritCargoArtifactsHook = <derivation inheritCargoArtifactsHook>;
  installCargoArtifactsHook = <derivation installCargoArtifactsHook>;
  installFromCargoBuildLogHook = <derivation installFromCargoBuildLogHook>;
  mkCargoDerivation = <function, args: {buildPhaseCargoCommand, cargoArtifacts, checkPhaseCargoCommand?, installPhaseCommand?}>;
  mkDummySrc = <function, args: {cargoLock?, extraDummyScript?, src}>;
  newScope = <function>;
  overrideScope = <function>;
  overrideScope' = <function>;
  overrideToolchain = <function>;
  packages = <function>;
  path = <function>;
  registryFromDownloadUrl = <function, args: {dl, fetchurlExtraArgs?, indexUrl, registryPrefix?}>;
  registryFromGitIndex = <function, args: {fetchurlExtraArgs?, indexUrl, rev}>;
  registryFromSparse = <function, args: {configSha256, fetchurlExtraArgs?, indexUrl}>;
  removeReferencesToVendoredSourcesHook = <derivation removeReferencesToVendoredSourcesHook>;
  rustc = <derivation rust-stable-with-components-2023-08-24>;
  rustfmt = <derivation rust-stable-with-components-2023-08-24>;
  urlForCargoPackage = <function, args: {checksum, name, source, version}>;
  vendorCargoDeps = <function>;
  vendorCargoRegistries = <function, args: {cargoConfigs?, lockPackages}>;
  vendorGitDeps = <function, args: {lockPackages}>;
  vendorMultipleCargoDeps = <function, args: {cargoConfigs?, cargoLockContentsList?, cargoLockList?, cargoLockParsedList?}>;
  writeTOML = <function>;
}
```

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/crane\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/crane.nix)



## config\.craneLib\.nightly



craneLib to use when nightly toolchain is needed

Default value is craneLib initialized with ` config.toolchain.nightly `



*Type:*
attribute set



*Default:*

```
{
  appendCrateRegistries = <function>;
  buildDepsOnly = <function, args: {cargoBuildCommand?, cargoCheckCommand?, cargoExtraArgs?, cargoTestCommand?, cargoTestExtraArgs?}>;
  buildPackage = <function, args: {cargoBuildCommand?, cargoExtraArgs?, cargoTestCommand?, cargoTestExtraArgs?}>;
  buildTrunkPackage = <function, args: {trunkExtraArgs?, trunkExtraBuildArgs?, trunkIndexPath?}>;
  callPackage = <function>;
  cargo = <derivation rust-nightly-complete-with-components-2023-09-19>;
  cargoAudit = <function, args: {advisory-db, cargoAuditExtraArgs?, cargoExtraArgs?, src}>;
  cargoBuild = <function, args: {cargoArtifacts, cargoExtraArgs?}>;
  cargoClippy = <function, args: {cargoArtifacts, cargoClippyExtraArgs?, cargoExtraArgs?}>;
  cargoDoc = <function, args: {cargoDocExtraArgs?, cargoExtraArgs?}>;
  cargoFmt = <function, args: {cargoExtraArgs?, rustFmtExtraArgs?}>;
  cargoHelperFunctionsHook = <derivation cargoHelperFunctionsHook>;
  cargoLlvmCov = <function, args: {cargoExtraArgs?, cargoLlvmCovCommand?, cargoLlvmCovExtraArgs?}>;
  cargoNextest = <function, args: {cargoArtifacts, cargoExtraArgs?, cargoNextestExtraArgs?, doInstallCargoArtifacts?, partitionType?, partitions?}>;
  cargoTarpaulin = <function, args: {cargoExtraArgs?, cargoTarpaulinExtraArgs?}>;
  cargoTest = <function, args: {cargoArtifacts, cargoExtraArgs?, cargoTestExtraArgs?}>;
  cleanCargoSource = <function>;
  cleanCargoToml = <function, args: {cargoToml?, cargoTomlContents?}>;
  clippy = <derivation rust-nightly-complete-with-components-2023-09-19>;
  configureCargoCommonVarsHook = <derivation configureCargoCommonVarsHook>;
  configureCargoVendoredDepsHook = <derivation configureCargoVendoredDepsHook>;
  craneUtils = <derivation crane-utils-0.1.0>;
  crateNameFromCargoToml = <function>;
  crateRegistries = {
    "registry+https://github.com/rust-lang/crates.io-index" = {
      downloadUrl = "https://crates.io/api/v1/crates/{crate}/{version}/download";
      fetchurlExtraArgs = { };
    };
  };
  devShell = <function, args: {checks?, inputsFrom?, packages?}>;
  downloadCargoPackage = <function, args: {checksum, name, version}>;
  downloadCargoPackageFromGit = <function, args: {allRefs?, git, ref?, rev}>;
  filterCargoSources = <function>;
  findCargoFiles = <function>;
  inheritCargoArtifactsHook = <derivation inheritCargoArtifactsHook>;
  installCargoArtifactsHook = <derivation installCargoArtifactsHook>;
  installFromCargoBuildLogHook = <derivation installFromCargoBuildLogHook>;
  mkCargoDerivation = <function, args: {buildPhaseCargoCommand, cargoArtifacts, checkPhaseCargoCommand?, installPhaseCommand?}>;
  mkDummySrc = <function, args: {cargoLock?, extraDummyScript?, src}>;
  newScope = <function>;
  overrideScope = <function>;
  overrideScope' = <function>;
  overrideToolchain = <function>;
  packages = <function>;
  path = <function>;
  registryFromDownloadUrl = <function, args: {dl, fetchurlExtraArgs?, indexUrl, registryPrefix?}>;
  registryFromGitIndex = <function, args: {fetchurlExtraArgs?, indexUrl, rev}>;
  registryFromSparse = <function, args: {configSha256, fetchurlExtraArgs?, indexUrl}>;
  removeReferencesToVendoredSourcesHook = <derivation removeReferencesToVendoredSourcesHook>;
  rustc = <derivation rust-nightly-complete-with-components-2023-09-19>;
  rustfmt = <derivation rust-nightly-complete-with-components-2023-09-19>;
  urlForCargoPackage = <function, args: {checksum, name, source, version}>;
  vendorCargoDeps = <function>;
  vendorCargoRegistries = <function, args: {cargoConfigs?, lockPackages}>;
  vendorGitDeps = <function, args: {lockPackages}>;
  vendorMultipleCargoDeps = <function, args: {cargoConfigs?, cargoLockContentsList?, cargoLockList?, cargoLockParsedList?}>;
  writeTOML = <function>;
}
```

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/crane\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/crane.nix)



## config\.craneLib\.stable



craneLib to use when stable toolchain is needed

Default value is craneLib initialized with ` config.toolchain.stable `



*Type:*
attribute set



*Default:*

```
{
  appendCrateRegistries = <function>;
  buildDepsOnly = <function, args: {cargoBuildCommand?, cargoCheckCommand?, cargoExtraArgs?, cargoTestCommand?, cargoTestExtraArgs?}>;
  buildPackage = <function, args: {cargoBuildCommand?, cargoExtraArgs?, cargoTestCommand?, cargoTestExtraArgs?}>;
  buildTrunkPackage = <function, args: {trunkExtraArgs?, trunkExtraBuildArgs?, trunkIndexPath?}>;
  callPackage = <function>;
  cargo = <derivation rust-stable-with-components-2023-08-24>;
  cargoAudit = <function, args: {advisory-db, cargoAuditExtraArgs?, cargoExtraArgs?, src}>;
  cargoBuild = <function, args: {cargoArtifacts, cargoExtraArgs?}>;
  cargoClippy = <function, args: {cargoArtifacts, cargoClippyExtraArgs?, cargoExtraArgs?}>;
  cargoDoc = <function, args: {cargoDocExtraArgs?, cargoExtraArgs?}>;
  cargoFmt = <function, args: {cargoExtraArgs?, rustFmtExtraArgs?}>;
  cargoHelperFunctionsHook = <derivation cargoHelperFunctionsHook>;
  cargoLlvmCov = <function, args: {cargoExtraArgs?, cargoLlvmCovCommand?, cargoLlvmCovExtraArgs?}>;
  cargoNextest = <function, args: {cargoArtifacts, cargoExtraArgs?, cargoNextestExtraArgs?, doInstallCargoArtifacts?, partitionType?, partitions?}>;
  cargoTarpaulin = <function, args: {cargoExtraArgs?, cargoTarpaulinExtraArgs?}>;
  cargoTest = <function, args: {cargoArtifacts, cargoExtraArgs?, cargoTestExtraArgs?}>;
  cleanCargoSource = <function>;
  cleanCargoToml = <function, args: {cargoToml?, cargoTomlContents?}>;
  clippy = <derivation rust-stable-with-components-2023-08-24>;
  configureCargoCommonVarsHook = <derivation configureCargoCommonVarsHook>;
  configureCargoVendoredDepsHook = <derivation configureCargoVendoredDepsHook>;
  craneUtils = <derivation crane-utils-0.1.0>;
  crateNameFromCargoToml = <function>;
  crateRegistries = {
    "registry+https://github.com/rust-lang/crates.io-index" = {
      downloadUrl = "https://crates.io/api/v1/crates/{crate}/{version}/download";
      fetchurlExtraArgs = { };
    };
  };
  devShell = <function, args: {checks?, inputsFrom?, packages?}>;
  downloadCargoPackage = <function, args: {checksum, name, version}>;
  downloadCargoPackageFromGit = <function, args: {allRefs?, git, ref?, rev}>;
  filterCargoSources = <function>;
  findCargoFiles = <function>;
  inheritCargoArtifactsHook = <derivation inheritCargoArtifactsHook>;
  installCargoArtifactsHook = <derivation installCargoArtifactsHook>;
  installFromCargoBuildLogHook = <derivation installFromCargoBuildLogHook>;
  mkCargoDerivation = <function, args: {buildPhaseCargoCommand, cargoArtifacts, checkPhaseCargoCommand?, installPhaseCommand?}>;
  mkDummySrc = <function, args: {cargoLock?, extraDummyScript?, src}>;
  newScope = <function>;
  overrideScope = <function>;
  overrideScope' = <function>;
  overrideToolchain = <function>;
  packages = <function>;
  path = <function>;
  registryFromDownloadUrl = <function, args: {dl, fetchurlExtraArgs?, indexUrl, registryPrefix?}>;
  registryFromGitIndex = <function, args: {fetchurlExtraArgs?, indexUrl, rev}>;
  registryFromSparse = <function, args: {configSha256, fetchurlExtraArgs?, indexUrl}>;
  removeReferencesToVendoredSourcesHook = <derivation removeReferencesToVendoredSourcesHook>;
  rustc = <derivation rust-stable-with-components-2023-08-24>;
  rustfmt = <derivation rust-stable-with-components-2023-08-24>;
  urlForCargoPackage = <function, args: {checksum, name, source, version}>;
  vendorCargoDeps = <function>;
  vendorCargoRegistries = <function, args: {cargoConfigs?, lockPackages}>;
  vendorGitDeps = <function, args: {lockPackages}>;
  vendorMultipleCargoDeps = <function, args: {cargoConfigs?, cargoLockContentsList?, cargoLockList?, cargoLockParsedList?}>;
  writeTOML = <function>;
}
```

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/crane\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/crane.nix)



## config\.direnv\.enable



Whether to enable direnv integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/direnv\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/direnv.nix)



## config\.env\.shellHooks



List of init hooks to execute when shell is entered



*Type:*
list of string



*Default:*

```
[
  ""
]
```

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/env\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/env.nix)



## config\.env\.shellPackages



Packages to include in all dev shells



*Type:*
list of package



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/env\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/env.nix)



## config\.git\.commit-msg\.enable



Whether to enable git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.commit-msg\.hooks



Attrset of hooks to to execute during git commit-msg hook



*Type:*
attribute set of (null or string or path)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.commit-template\.enable



Whether to enable git commit message template\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.commit-template\.body



The body of the template content



*Type:*
string or path



*Default:*

```
''
  # Explain *why* this change is being made                width limit ->|
''
```

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.commit-template\.head



The head of the template content



*Type:*
string or path



*Default:*
` "" `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.pre-commit\.enable



Whether to enable git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.pre-commit\.hooks



Attrset of hooks to to execute during git pre-commit hook



*Type:*
attribute set of (null or string or path)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.pre-commit\.trailing_newline



Whether to enable git pre-commit trailing newline check \.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.git\.pre-commit\.trailing_whitespace



Whether to enable git pre-commit trailing whitespace check \.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/git.nix)



## config\.github\.ci\.enable



Whether to enable just integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github.nix)



## config\.github\.ci\.buildOutputs



List of outputs to build



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github.nix)



## config\.github\.ci\.workflows



Set of workflows to generate in ` .github/workflows/ `"\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github.nix)



## config\.github\.ci\.workflows\.\<name>\.enable



Whether this workflow file should be generated\. This
option allows specific workflow files to be disabled\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github.nix)



## config\.github\.ci\.workflows\.\<name>\.content



Content of the workflow



*Type:*
attribute set of anything



*Default:*
` null `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/github.nix)



## config\.just\.enable



Whether to enable just integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just.nix)



## config\.just\.rules



Attrset of section of justfile (possibly with multiple rules)

Notably the name is used only for config identification (e\.g\. disabling) and actual
justfile rule name must be used in the value (content of the file)\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just.nix)



## config\.just\.rules\.\<name>\.enable



Whether this rule should be generated\. This
option allows specific rules to be disabled\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just.nix)



## config\.just\.rules\.\<name>\.content



Order of this rule in relation to the others ones\.
The semantics are the same as with ` lib.mkOrder `\. Smaller values have
a greater priority\.



*Type:*
string or path



*Default:*
` 1000 `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just.nix)



## config\.just\.rules\.\<name>\.priority



Order of this rule in relation to the others ones\.
The semantics are the same as with ` lib.mkOrder `\. Smaller values have
a greater priority\.



*Type:*
signed integer



*Default:*
` 1000 `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/just.nix)



## config\.rootDir



Set of files that will be generated as as “Flakebox Root Dir”\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.enable



Whether this root dir file should be generated\. This
option allows specific root dir files to be disabled\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.mode



If set to something else than ` symlink `,
the file is copied instead of symlinked, with the given
file mode\.



*Type:*
string



*Default:*
` "symlink" `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.source



Path of the source file\.



*Type:*
path

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.target



Name of symlink (relative to root dir)\. Defaults to the attribute name\.



*Type:*
string

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.text



Text of the file\.



*Type:*
null or strings concatenated with “\\n”



*Default:*
` null `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rootDirPackage



Derivation containing all rootDir files/symlinks



*Type:*
package

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rootDir.nix)



## config\.rust\.pre-commit\.clippy\.enable



Whether to enable clippy check in pre-commit hook\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust.nix)



## config\.rust\.pre-commit\.leftover-dbg\.enable



Whether to enable leftover ` dbg! ` check in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust.nix)



## config\.rust\.rustfmt\.enable



Whether to enable generation of \.rustfmt\.toml\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust.nix)



## config\.rust\.rustfmt\.content



The content of the file



*Type:*
string

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/rust.nix)



## config\.semgrep\.enable



Whether to enable semgrep integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/semgrep\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/semgrep.nix)



## config\.semgrep\.pre-commit\.enable



Whether to enable semgrep git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/semgrep\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/semgrep.nix)



## config\.shellcheck\.enable



Whether to enable shellcheck integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/shellcheck\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/shellcheck.nix)



## config\.shellcheck\.pre-commit\.enable



Whether to enable shellcheck git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/shellcheck\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/shellcheck.nix)



## config\.toolchain\.channel\.default



The channel to source the default toolchain from

Defaults to the the value of the stable channel\.



*Type:*
string



*Default:*
` "stable" `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.channel\.nightly



The channel to source the nightly toolchain from



*Type:*
string



*Default:*
` "complete" `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.channel\.stable



The channel to source the stable toolchain from



*Type:*
string



*Default:*
` "stable" `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.components



Components to include in the default toolchains



*Type:*
list of string



*Default:*

```
[
  "rustc"
  "cargo"
  "clippy"
  "rust-analysis"
  "rust-src"
]
```

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.default



Default toolchain to use



*Type:*
package



*Default:*
` <derivation rust-stable-with-components-2023-08-24> `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.nightly



Nightly channel toolchain



*Type:*
package



*Default:*
` <derivation rust-nightly-complete-with-components-2023-09-19> `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.rust-analyzer



rust-analyzer package to use in the shell and lints

Separate from the toolchain as it’s common to want a custom version\.

Defaults to the standard rust-analyzer from nixpkgs input\.



*Type:*
package



*Default:*
` <derivation rust-analyzer-2023-05-15> `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.rustfmt



rustfmt package to use in the shell and lints

Separate from the toolchain as it’s common to want a custom (nightly) version,
for all the great yet unstable features\.

Defaults to the rustfmt from the nightly channel\.



*Type:*
package



*Default:*
` <derivation rust-nightly-complete-with-components-2023-09-19> `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.toolchain\.stable



Stable channel toolchain

Toolchain to use in situations that require stable toolchain\.



*Type:*
package



*Default:*
` <derivation rust-stable-with-components-2023-08-24> `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/toolchain.nix)



## config\.typos\.enable



Whether to enable typos integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/typos\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/typos.nix)



## config\.typos\.pre-commit\.enable



Whether to enable typos git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/typos\.nix](file:///nix/store/n4q6rydhxw1wjp3k4vg8xi0qpif5zb1s-source/lib/modules/typos.nix)


