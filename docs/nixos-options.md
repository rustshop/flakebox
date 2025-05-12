## config\.cargo\.pre-commit\.cargo-fmt\.enable

Whether to enable cargo fmt check in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/cargo\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/cargo.nix)



## config\.cargo\.pre-commit\.cargo-lock\.enable



Whether to enable cargo lock check in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/cargo\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/cargo.nix)



## config\.convco\.enable



Whether to enable convco integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/convco\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/convco.nix)



## config\.convco\.commit-msg\.enable



Whether to enable convco git commit-msg hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/convco\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/convco.nix)



## config\.craneMkLib



craneLib to use by default

Default value is craneLib initialized with ` config.toolchain.channel ` toolchain with ` config.toolchain.components `



*Type:*
attribute set



*Default:*
` <function> `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/crane\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/crane.nix)



## config\.direnv\.enable



Whether to enable direnv integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/direnv\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/direnv.nix)



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
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/env\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/env.nix)



## config\.env\.shellPackages



Packages to include in all dev shells



*Type:*
list of package



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/env\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/env.nix)



## config\.flakebox\.init\.enable



Whether to enable the ` flakebox init ` in dev shells\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/flakbox\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/flakbox.nix)



## config\.flakebox\.lint\.enable



Whether to enable the flakebox binary integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/flakbox\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/flakbox.nix)



## config\.git\.commit-msg\.enable



Whether to enable git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.commit-msg\.hooks



Attrset of hooks to to execute during git commit-msg hook



*Type:*
attribute set of (null or string or path)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.commit-template\.enable



Whether to enable git commit message template\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



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
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.commit-template\.head



The head of the template content



*Type:*
string or path



*Default:*
` "" `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.pre-commit\.enable



Whether to enable git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.pre-commit\.hooks



Attrset of hooks to to execute during git pre-commit hook



*Type:*
attribute set of (null or string or path)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.pre-commit\.trailing_newline



Whether to enable git pre-commit trailing newline check\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.git\.pre-commit\.trailing_whitespace



Whether to enable git pre-commit trailing whitespace check\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/git.nix)



## config\.github\.ci\.enable



Whether to enable just integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.buildMatrix



Build matrix to use in the workflow ` strategy.matrix ` of ` build ` job



*Type:*
attribute set



*Default:*

```
{
  host = [
    "macos-x86_64"
    "macos-aarch64"
    "linux"
  ];
  include = [
    {
      host = "linux";
      runs-on = "ubuntu-latest";
      timeout = 60;
    }
    {
      host = "macos-x86_64";
      runs-on = "macos-13";
      timeout = 60;
    }
    {
      host = "macos-aarch64";
      runs-on = "macos-14";
      timeout = 60;
    }
  ];
}
```

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.buildMatrixExtra



Additional build matrix to deep merge with ` buildMatrix `



*Type:*
attribute set



*Default:*
` { } `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.buildOutputs



List of outputs to build



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.cachixRepo



Name of the cachix repository to use for cache



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.flakeSelfCheck\.enable



Whether to enable flake self-check\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.runsOn



Value of a runs-on to use for default Linu workflows (lint, self-check, etc\.)



*Type:*
anything



*Default:*
` "ubuntu-latest" `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.workflows



Set of workflows to generate in ` .github/workflows/ `"\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.workflows\.\<name>\.enable



Whether this workflow file should be generated\. This
option allows specific workflow files to be disabled\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.github\.ci\.workflows\.\<name>\.content



Content of the workflow



*Type:*
attribute set of anything



*Default:*
` null `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/github.nix)



## config\.just\.enable



Whether to enable just integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just.nix)



## config\.just\.importPaths



List of files to generate ` import ... ` statement for (as a strings in ` import ` Justfile directive)



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just.nix)



## config\.just\.rules



Attrset of section of justfile (possibly with multiple rules)

Notably the name is used only for config identification (e\.g\. disabling) and actual
justfile rule name must be used in the value (content of the file)\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just.nix)



## config\.just\.rules\.\<name>\.enable



Whether this rule should be generated\. This
option allows specific rules to be disabled\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just.nix)



## config\.just\.rules\.\<name>\.content



Full just rule declaration\. (can be path to a file)

Note that the full declaration defines the actual justfile rule name



*Type:*
string or path



*Example:*

```
''
  # run tests
  test: build
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f Cargo.toml ]; then
      cd {{invocation_directory()}}
    fi
    cargo test
''
```

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just.nix)



## config\.just\.rules\.\<name>\.priority



Order of this rule in relation to the others ones\.
The semantics are the same as with ` lib.mkOrder `\. Smaller values have
a greater priority\.



*Type:*
signed integer



*Default:*
` 1000 `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/just.nix)



## config\.motd\.enable



Whether to enable message of a day\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/motd\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/motd.nix)



## config\.motd\.command



Command to execute to display motd



*Type:*
string



*Default:*
` "" `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/motd\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/motd.nix)



## config\.nix\.nixfmt\.enable



Whether to enable nixfmt support\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/nix\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/nix.nix)



## config\.nix\.nixfmt\.pre-commit\.enable



Whether to enable check nixfmt in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/nix\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/nix.nix)



## config\.rootDir



Set of files that will be generated as as “Flakebox Root Dir”\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.enable



Whether this root dir file should be generated\. This
option allows specific root dir files to be disabled\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.mode



If set to something else than ` symlink `,
the file is copied instead of symlinked, with the given
file mode\.



*Type:*
string



*Default:*
` "symlink" `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.source



Path of the source file\.



*Type:*
path

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.target



Name of symlink (relative to root dir)\. Defaults to the attribute name\.



*Type:*
string

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rootDir\.\<name>\.text



Text of the file\.



*Type:*
null or strings concatenated with “\\n”



*Default:*
` null `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rootDirPackage



Derivation containing all rootDir files/symlinks



*Type:*
package

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rootDir.nix)



## config\.rust\.pre-commit\.clippy\.enable



Whether to enable clippy check in pre-commit hook\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust.nix)



## config\.rust\.pre-commit\.leftover-dbg\.enable



Whether to enable leftover ` dbg! ` check in pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust.nix)



## config\.rust\.rustfmt\.enable



Whether to enable generation of \.rustfmt\.toml\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust.nix)



## config\.rust\.rustfmt\.content



The content of the file



*Type:*
string

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/rust.nix)



## config\.semgrep\.enable



Whether to enable semgrep integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/semgrep\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/semgrep.nix)



## config\.semgrep\.pre-commit\.enable



Whether to enable semgrep git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/semgrep\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/semgrep.nix)



## config\.shellcheck\.enable



Whether to enable shellcheck integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/shellcheck\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/shellcheck.nix)



## config\.shellcheck\.pre-commit\.enable



Whether to enable shellcheck git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/shellcheck\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/shellcheck.nix)



## config\.toolchain\.channel



The channel to source the default toolchain from

Defaults to the the value of the stable channel\.



*Type:*
string



*Default:*
` "stable" `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/toolchain\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/toolchain.nix)



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
  "rust-analyzer"
  "rust-src"
]
```

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/toolchain\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/toolchain.nix)



## config\.toolchain\.rustfmt



rustfmt package to use in the shell and lints

Separate from the toolchain as it’s common to want a custom (nightly) version,
for all the great yet unstable features\.

Defaults to the rustfmt from the nightly channel default profile\.



*Type:*
package



*Default:*
` <derivation rust-nightly-default-with-components-2025-04-18> `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/toolchain\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/toolchain.nix)



## config\.typos\.enable



Whether to enable typos integration\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/typos\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/typos.nix)



## config\.typos\.pre-commit\.enable



Whether to enable typos git pre-commit hook\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [/nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/typos\.nix](file:///nix/store/zca72vihhy4kb03a90m7z8r105vz8c1m-source/lib/modules/typos.nix)


