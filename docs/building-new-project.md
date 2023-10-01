# Tutorial: Building Rust with Nix in a new project

In this tutorial we will:

* start a new Rust project from scratch;
* set up Flakebox in it;
* use it to compile our project;
* then cross-compile it;
* introduce some non-trivial C-dependencies;
* then compile and cross-compile again;
* and set up a cross-compiling dev shell.

## Creating new project

Create a new project:

```
> mkdir flakebox-tutorial
> cd flakebox-tutorial/
```

Since we don't have a dev shell yet, initialize new project with `cargo` from nixpkgs:

```
> nix run nixpkgs#cargo -- init
     Created binary (application) package
```

(If the above command doesn't work, probably you need to setup Nix with Flakes enabled).

Init Nix Flake inside the project:

```
> nix flake init
wrote: /home/dpc/tmp/flakebox-tutorial/flake.nix
```

Commit the results as a good starting point:

```
> git add *
> git commit -a -m "Empty project"
[master (root-commit) 01e823b] Empty project
 3 files changed, 22 insertions(+)
 create mode 100644 Cargo.toml
 create mode 100644 flake.nix
 create mode 100644 src/main.rs
```
 
Add `nixpkgs` and `flakebox` as inputs (dependencies) to your flake.
Note that I use `hx` as my text editor, but you can use whatever
you like.

```
> hx flake.nix
> git diff HEAD
```

```diff
diff --git a/flake.nix b/flake.nix
index a96aa14..25ce16f 100644
--- a/flake.nix
+++ b/flake.nix
@@ -1,7 +1,16 @@
 {
   description = "A very basic flake";
 
-  outputs = { self, nixpkgs }: {
+  inputs = {
+    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
+
+    flakebox = {
+      url = "github:rustshop/flakebox";
+      inputs.nixpkgs.follows = "nixpkgs";
+    };
+  };
+
+  outputs = { self, nixpkgs, flakebox }: {
 
     packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
```
 
Check if everything is OK, then commit it if that's the case:

```
 > nix flake check .#
warning: Git tree '/home/dpc/tmp/flakebox-tutorial' is dirty
> git commit -a -m "Flake inputs"
[master ea52e46] Flake inputs
 2 files changed, 330 insertions(+), 1 deletion(-)
 create mode 100644 flake.lock
```

Note: If you're getting errors like:

```
       error: a 'aarch64-darwin' with features {} is required to build '/nix/store/ag23kdyxy0is5w3jj8lplz749bhwgnhw-flakebox-flakebox-ci-yaml-gen.drv', but I am a 'x86_64-linux' with features {benchmark, big-parallel, kvm, nixos-test}
```

it means your `nix` is too old. Use `nix run nixpkgs#nix flake check` instead to run a newest version. It's an awesome use of Nix Flakes, so get familiar with it.

OK. That's the basic setup. It would probably be faster to use a template,
but doing it from scratch is a good learning experience.

Now let's do something actually interesting with it.

## Setting up Flakebox dev shell

We still don't have even `cargo` for our project, so let's do that next:

```
> hx flake.nix
> git diff
```

```diff
diff --git a/flake.nix b/flake.nix
index 25ce16f..f09763b 100644
--- a/flake.nix
+++ b/flake.nix
@@ -8,13 +8,20 @@
       url = "github:rustshop/flakebox";
       inputs.nixpkgs.follows = "nixpkgs";
     };
-  };
-
-  outputs = { self, nixpkgs, flakebox }: {
-
-    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
-
-    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
 
+    flake-utils.url = "github:numtide/flake-utils";
   };
+
+  outputs = { self, nixpkgs, flakebox, flake-utils }:
+    flake-utils.lib.eachDefaultSystem (system:
+      let
+        flakeboxLib = flakebox.lib.${system} { };
+      in
+      {
+        devShells = {
+          default = flakeboxLib.mkDevShell {
+            packages = [ ];
+          };
+        };
+      });
 }
 ```
 
Since that's a bit handful, let me paste the whole content:
 
 
```
> cat flake.nix 
```
 
```nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    flakebox = {
      url = "github:rustshop/flakebox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flakebox, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        flakeboxLib = flakebox.lib.${system} { };
      in
      {
        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ ];
          };
        };
      });
}
```

I've added a `eachDefaultSystem` from `flake-utils`. This is
a common pattern taking care of implementing all outputs from
our Flake on all system architectures.

But the most important part is initializing `flakeboxLib`,
and then using it to create a new `default` `devShell`.

Verify the Nix code is still OK:

```
> nix run nixpkgs#nix flake check
warning: Git tree '/home/dpc/tmp/flakebox-tutorial' is dirty
warning: The check omitted these incompatible systems: aarch64-darwin, aarch64-linux, x86_64-darwin
Use '--all-systems' to check all.
```

And if so, enter the new dev shell we created:


```
> nix develop
warning: Git tree '/home/dpc/tmp/flakebox-tutorial' is dirty
⚠️  Flakebox files not installed. Call `flakebox install`.
```

It works. Ignore the prompt for now and commit our progress:

```
> git commit -a -m "Flakebox dev shell"
[master eb3ca46] Flakebox dev shell
 2 files changed, 55 insertions(+), 14 deletions(-)
```
 
Now, run the `flakebox install` to install dev shell files into your project:

```
> flakebox install
```

If you see:

```
direnv: error /home/dpc/tmp/flakebox-tutorial/.envrc is blocked. Run `direnv allow` to approve its content
```

it's because you have `direnv` installed on your system and flakebox enabled support for it. If you allow
it with `direnv allow`, you will automatically enter your dev shell each time you `cd` into your project.

Verify the files installed by `flakebox install`:

```
> git status
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   .config/fakeroot/current
	new file:   .config/flakebox/shellHook.sh
	new file:   .config/semgrep.yaml
	new file:   .envrc
	new file:   .github/workflows/flakebox-ci.yml
	new file:   .github/workflows/flakebox-flakehub-publish.yml
	new file:   .rustfmt.toml
	new file:   justfile
	new file:   misc/git-hooks/commit-msg
	new file:   misc/git-hooks/commit-template.txt
	new file:   misc/git-hooks/pre-commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	.gitignore
```

The exact output might differ. As you can see Flakebox installed
and configured all sorts of extra functionality.

See if everything still works be leaving and entering the shell again:

```
> exit
> nix develop
warning: Git tree '/home/dpc/tmp/flakebox-tutorial' is dirty
💡 Run 'just' for a list of available 'just ...' helper recipes
```

Commit the changes:

```
> git commit -a -m "Setup flakebox dev shell"
Skipping semgrep check: .config/semgrep.yaml empty
tail: error reading 'standard input': Is a directory
error: the lock file /home/dpc/tmp/flakebox-tutorial/Cargo.lock needs to be updated but --locked was passed to prevent this
If you want to try to generate the lock file without accessing the network, remove the --locked flag and use --offline instead.
```

Oh. It's the dev shell already doing its work. It detected that `Cargo.lock` is not up to date,
which is not a state we want to commit.

Fix it and try again:

```
> cargo build
   Compiling flakebox-tutorial v0.1.0 (/home/dpc/tmp/flakebox-tutorial)
    Finished dev [unoptimized + debuginfo] target(s) in 0.46s
> git add .gitignore Cargo.lock❄️ 
> git commit -a -m "Setup flakebox dev shell"
Skipping semgrep check: .config/semgrep.yaml empty
tail: error reading 'standard input': Is a directory
[master f387a84] Setup flakebox dev shell
 11 files changed, 390 insertions(+)
 create mode 120000 .config/fakeroot/current
# ... skipped for brevity
```

That's better. There's more to Flakebox Dev Shells, but this will do for now.
Let's move to the cool part - building your project with Nix.

## Building Rust code with Flakebox

The easiest and most versatile way to build Rust with Flakebox is using
`flakeboxLib.



```
> git diff HEAD
```

```diff
diff --git a/flake.nix b/flake.nix
index f09763b..a65ba7a 100644
--- a/flake.nix
+++ b/flake.nix
@@ -16,8 +16,38 @@
     flake-utils.lib.eachDefaultSystem (system:
       let
         flakeboxLib = flakebox.lib.${system} { };
+
+        rustSrc = flakeboxLib.filter.filterSubdirs {
+          root = builtins.path {
+            name = "flakebox-tutorial";
+            path = ./.;
+          };
+          dirs = [
+            "Cargo.toml"
+            "Cargo.lock"
+            ".cargo"
+            "src"
+          ];
+        };
+
+        outputs =
+          (flakeboxLib.craneMultiBuild { }) (craneLib':
+            let
+              craneLib = (craneLib'.overrideArgs {
+                pname = "flexbox-multibuild";
+                src = rustSrc;
+              });
+            in
+            rec {
+              workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
+              workspaceBuild = craneLib.buildWorkspace {
+                cargoArtifacts = workspaceDeps;
+              };
+              flakebox-tutorial = craneLib.buildPackage { };
+            });
       in
       {
+        legacyPackages = outputs;
         devShells = {
           default = flakeboxLib.mkDevShell {
             packages = [ ];
```

Let's check if it works:

```
> nix flake check
```

```
> nix build .#dev.flakebox-tutorial
warning: Git tree '/home/dpc/tmp/flakebox-tutorial' is dirty
> file result/bin/flakebox-tutorial 
result/bin/flakebox-tutorial: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib/ld-linux-x86-64.so.2, for GNU/Linux 3.10.0, not stripped
> ./result/bin/flakebox-tutorial 
Hello, world!
```

Tada! It's working! `nix build` creates a `result/` symlink in the current directory pointing the result of the requested derivation (build output in non-Nix).

Good time to add `result/` to `.gitignore`:

```
> hx .gitignore
> cat .gitignore 
/target
/result
```

Commit the current state and I can explain in more details what is
this new Nix code doing and what else you can do with it (spoiler: cross-compilation and different cargo build profiles!).


```
> git add *
> git commit -a -m "Add initial build system"
Skipping semgrep check: .config/semgrep.yaml empty
[master e681b24] Add initial build system
 1 file changed, 30 insertions(+)
```

## Building Rust code with Flakebox - explanation

Let's discuss each part of the code:

```
        flakeboxLib = flakebox.lib.${system} { };
```

`let ... in <expr>` in Nix is used to bind values
to names, that can later be used in `<expr>` following
in.

Our first name binding is `flakeboxLib` which exposes all
Flakebox APIs. `flakebox` is the name of the input
defined in the flake, `flakebox.lib.${system}` is
the library output it exposes for the current `system`.
`flakebox.lib.${system} { }` is a function call, where
`{ }` are the arguments (empty set, defaults).

The next binding is:

```nix
        rustSrc = flakeboxLib.filter.filterSubdirs {
          root = builtins.path {
            name = "flakebox-tutorial";
            path = ./.;
          };
          dirs = [
            "Cargo.toml"
            "Cargo.lock"
            ".cargo"
            "src"
          ];
        };
```

This `filter.filterSubdirs` is a function exposed by
`flakeboxLib` and is used for easy source code filtering.
This is useful to avoid having to rebuild our Rust project
when only irrelevant files changed. It's not strictly
necessary, but almost any project will benefit
from avoiding redoing work when it's not necessary.
As `Nix` doesn't understand the details of how
`cargo` works, the only way to explain it which
files can change the result of a build is by
filtering them out. The details of source code filtering
will be explained elsewhere in the documentation.


The last name binding is:

```nix
        outputs =
          (flakeboxLib.craneMultiBuild { }) (craneLib':
            let
              craneLib = (craneLib'.overrideArgs {
                pname = "flexbox-multibuild";
                src = rustSrc;
              });
            in
            rec {
              workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
              workspaceBuild = craneLib.buildWorkspace {
                cargoArtifacts = workspaceDeps;
              };
              flakebox-tutorial = craneLib.buildPackage { };
            });
```


`(flakeboxLib.craneMultiBuild { })` is a function call of `craneMultiBuild` function
with an empty set `{ }` as an argument. This function is meant for conveniently
building Rust across cargo build profiles and toolchains.

It returns a function that must be called with ... another function as an argument.
You can see why functional programming is called, well, functional.

The rest of this code block `(craneLib': /* ... */ });` is the actual build
function. The `craneLib'` is the the [crane](https://crane.dev/) library instance
already pre-configured for the caller-requested environment.

[crane](https://crane.dev/) is a Nix library for building `cargo` projects.
It might feel a little bit intimidating at first, but I encourage you to
read [crane's Introduction pages](https://crane.dev/introduction.html)
(all of them).

Notably `craneLib` is already pre-configured for you, so you might notice
that in our example we don't need to pass as many examples. Also,
Flakebox enhanced `crane` with certain extra functionality for
even more convenient use.

The following
```nix
            let
              craneLib = (craneLib'.overrideArgs {
                pname = "flexbox-multibuild";
                src = rustSrc;
              });
            in
```

defines a new name binding. The value of it is the original `craneLib'`
with certain arguments overridden. `pname` sets the name of the derivation
and `src` sets the source directory for `crane` to build.

Finally:

```nix
            rec {
              workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
              workspaceBuild = craneLib.buildWorkspace {
                cargoArtifacts = workspaceDeps;
              };
              flakebox-tutorial = craneLib.buildPackage { };
            }
```

defines a set with 3 derivations.

`flakebox-tutorial` corresponds to `cargo build` and taking all the
resulting binaries as the result of the whole derivation.

`workspaceBuild` corresponds to `cargo build --workspace`, but notably
it's result (output) is the whole `./target` directory after `cargo`
completed. It also uses `cargoArtifacts = workspaceDeps;` which means
it doesn't start from scratch, but instead takes the result of `workspaceDeps`
and uses it as starting point (`./target` content to be precise).

`workspaceDeps` uses a crane's special sauce "deps only" build which
compiles only the dependencies of the whole workspace. This way
the resulting `./target/` doesn't need to get rebuild unless
project dependencies changed, which improves the caching by a lot.


The result of this whole call to `craneMultiBuild` is binded in `outputs` name
and conceptually contains a matrix of all supported cargo build profiles and
supported toolchains:

* `<output>` - i.e. `workspaceDeps`, `workspaceBuild`, `flakebox-tutorial` are builds using default (`release`) building profile and `default` (native) toolchain
* `<profile>.<output>` - e.g. `dev.workspaceDeps`, `release.workspaceBuild`, `ci.flakebox-tutorial` are builds using `<ci>` building profile and `default` (native) toolchain
* `<toolchain>.<profile>.<output>` - e.g. `nightly.dev.workspaceDeps`, `aarch64-android.release.flakebox-tutorial` are builds using `<ci>` build profile and `<toolchain>`

By default `dev`, `ci`, and `release` profiles are available, and `default`, `stable`, `nightly` are the native toolchains, and cross-compilation toolchains include:

* `aarch64-android`
* `arm-android`
* `x86_64-android`
* `i686-android`
* `aarch64-darwin`
* `x86_64-darwin`
* `aarch64-linux`

Please be aware that some of these toolchains will take a very long time to actually compile.

Finally

```nix
        legacyPackages = outputs;
```

exposes all these outputs as a "legacy packages" in our Flake. It's a bit of a hack, but will work for now.

## Building Rust code with Flakebox - advanced


Try to build the cod now:

```
> nix build .#flakebox-tutorial
20:18:37 ~/tmp/flakebox-tutorial  master [?] is 📦 v0.1.0 🦀v1.72.0 ❄️ 
> file result/bin/flakebox-tutorial
result/bin/flakebox-tutorial: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib/ld-linux-x86-64.so.2, for GNU/Linux 3.10.0, not stripped
```

The above is the release build using the default (native `stable`) toolchain.

Now build the whole workspace using `dev` mode of `nightly` toolchain and keep the whole output (`-L`):

```
> nix build -L .#dev.workspaceBuild
flexbox-multibuild-workspace-deps> cargoArtifacts not set, will not reuse any cargo artifacts
flexbox-multibuild-workspace-deps> unpacking sources
flexbox-multibuild-workspace-deps> unpacking source archive /nix/store/axsvfwi3xjaw3vmd93bx0h2k55hdyzbx-source
flexbox-multibuild-workspace-deps> source root is source
flexbox-multibuild-workspace-deps> patching sources
flexbox-multibuild-workspace-deps> Executing configureCargoCommonVars
flexbox-multibuild-workspace-deps> configuring
flexbox-multibuild-workspace-deps> will append /build/source/.cargo-home/config.toml with contents of /nix/store/5670gflg2yzqq7i7k1fygmydkphwwshz-vendor-cargo-deps/config.toml
flexbox-multibuild-workspace-deps> default configurePhase, nothing to do
flexbox-multibuild-workspace-deps> building
flexbox-multibuild-workspace-deps> ++ command cargo --version
flexbox-multibuild-workspace-deps> cargo 1.72.0 (103a7ff2e 2023-08-15)
flexbox-multibuild-workspace-deps> ++ command cargo doc --profile dev --workspace --locked
flexbox-multibuild-workspace-deps>    Compiling flakebox-tutorial v0.1.0 (/build/source)
flexbox-multibuild-workspace-deps>  Documenting flakebox-tutorial v0.1.0 (/build/source)
flexbox-multibuild-workspace-deps>     Finished dev [unoptimized + debuginfo] target(s) in 0.97s
# ... skipped for brevity
flexbox-multibuild-workspace> ++ command cargo build --profile dev --locked --workspace --all-targets
flexbox-multibuild-workspace>    Compiling flakebox-tutorial v0.1.0 (/build/source)
flexbox-multibuild-workspace>     Finished dev [unoptimized + debuginfo] target(s) in 0.23s
flexbox-multibuild-workspace> installing
flexbox-multibuild-workspace> compressing new content of target to /nix/store/pi6cww0zr4pp0rdl5n5v5yy3v11xf11y-flexbox-multibuild-workspace-0.1.0/target.tar.zst
flexbox-multibuild-workspace> /*stdin*\            : 29.52%   (  12.5 MiB =>   3.69 MiB, /nix/store/pi6cww0zr4pp0rdl5n5v5yy3v11xf11y-flexbox-multibuild-workspace-0.1.0/target.tar.zst)
flexbox-multibuild-workspace> post-installation fixup
flexbox-multibuild-workspace> shrinking RPATHs of ELF executables and libraries in /nix/store/pi6cww0zr4pp0rdl5n5v5yy3v11xf11y-flexbox-multibuild-workspace-0.1.0
flexbox-multibuild-workspace> checking for references to /build/ in /nix/store/pi6cww0zr4pp0rdl5n5v5yy3v11xf11y-flexbox-multibuild-workspace-0.1.0...
flexbox-multibuild-workspace> patching script interpreter paths in /nix/store/pi6cww0zr4pp0rdl5n5v5yy3v11xf11y-flexbox-multibuild-workspace-0.1.0
> ls -alh result/
total 24M
dr-xr-xr-x     2 root root   4.0K Dec 31  1969 .
drwxrwxr-t 38042 root nixbld  20M Sep 30 20:24 ..
-r--r--r--     2 root root   3.7M Dec 31  1969 target.tar.zst
lrwxrwxrwx     2 root root     98 Dec 31  1969 target.tar.zst.prev -> /nix/store/a76dbichnyhgza5ilrv516kdqc29j59d-flexbox-multibuild-workspace-deps-0.1.0/target.tar.zst
```

As you can see the `result` contains the actual compressed `target.tar.zst`. Well, the incremental layer of new/changed files and a link to a previous layer, to be precise.

Try cross-compiling:

```
> nix build .#aarch64-android.dev.flakebox-tutorial
> file result/bin/flakebox-tutorial
result/bin/flakebox-tutorial: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, with debug_info, not stripped
```

Yes. This is our tutorial project cross-compiled to aarch64 android. Just like that.


### Extra dependencies

Compiling a "hello world" project might seem too easy, so pretend there
are some nontrivial dependencies that need to be compiled as well:

```
> cargo add openssl
# ...
> cargo add libsqlite3-sys
# ...
```

Both of these dependencies are rather non-trivial, as they use C bindings, etc.

Try building them:

```
> cargo build
  --- stderr
  thread 'main' panicked at '

  Could not find directory of OpenSSL installation, and this `-sys` crate cannot
  proceed without this knowledge. If OpenSSL is installed and this crate had
  trouble finding it,  you can set the `OPENSSL_DIR` environment variable for the
  compilation process.

  Make sure you also have the development packages of openssl installed.
  For example, `libssl-dev` on Ubuntu or `openssl-devel` on Fedora.

  If you're in a situation where you think the directory *should* be found
  automatically, please open a bug at https://github.com/sfackler/rust-openssl
  and include information about your system as well as this message.

  $HOST = x86_64-unknown-linux-gnu
  $TARGET = x86_64-unknown-linux-gnu
  openssl-sys = 0.9.93

  ', /home/dpc/.cargo/registry/src/index.crates.io-6f17d22bba15001f/openssl-sys-0.9.93/build/find_normal.rs:190:5
  note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
warning: build failed, waiting for other jobs to finish...
```

Note that you don't have to use `nix build` all the time when working on your project.
When working locally, it's more convenient to rely on the tooling that you
are familiar with running in a dev shell.

Anyway - the compilation failed because it can't find native OpenSSL.

Add the necessary build inputs and re-enter the dev shell:


```
> hx flake.nix
> git diff
diff --git a/flake.nix b/flake.nix
index a65ba7a..f4c64d7 100644
--- a/flake.nix
+++ b/flake.nix
@@ -5,7 +5,7 @@
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
 
     flakebox = {
-      url = "github:rustshop/flakebox";
+      url = "github:rustshop/flakebox?rev=9e45d2c0b330a170721ada3fe3a73c38dcff763b";
       inputs.nixpkgs.follows = "nixpkgs";
     };
 
@@ -15,6 +15,11 @@
   outputs = { self, nixpkgs, flakebox, flake-utils }:
     flake-utils.lib.eachDefaultSystem (system:
       let
+
+        pkgs = import nixpkgs {
+          inherit system;
+        };
+
         flakeboxLib = flakebox.lib.${system} { };
 
         rustSrc = flakeboxLib.filter.filterSubdirs {
@@ -36,6 +41,10 @@
               craneLib = (craneLib'.overrideArgs {
                 pname = "flexbox-multibuild";
                 src = rustSrc;
+                buildInputs = [
+                  pkgs.openssl
+                ];
+
+                nativeBuildInputs = [
+                  pkgs.pkg-config
+                ];
               });
             in
             rec {
@@ -50,6 +59,10 @@
         legacyPackages = outputs;
         devShells = {
           default = flakeboxLib.mkDevShell {
+            buildInputs = [
+              pkgs.openssl
+            ];
+            nativeBuildInputs = [
+              pkgs.pkg-config
+            ];
             packages = [ ];
           };
         };
> nix flake check
# ...
> exit
> nix develop
```

And try again:

```
> cargo build
# ...
   Compiling openssl-sys v0.9.93
   Compiling openssl v0.10.57
   Compiling flakebox-tutorial v0.1.0 (/home/dpc/tmp/flakebox-tutorial)
    Finished dev [unoptimized + debuginfo] target(s) in 4.25s
```

And as a Nix derivation:

```
> nix build -L .#dev.flakebox-tutorial
flexbox-multibuild> shrinking RPATHs of ELF executables and libraries in /nix/store/yw7lfwmb664bns5xk3jg6196jj7zf3mw-flexbox-multibuild-0.1.0
flexbox-multibuild> shrinking /nix/store/yw7lfwmb664bns5xk3jg6196jj7zf3mw-flexbox-multibuild-0.1.0/bin/flakebox-tutorial
flexbox-multibuild> checking for references to /build/ in /nix/store/yw7lfwmb664bns5xk3jg6196jj7zf3mw-flexbox-multibuild-0.1.0...
flexbox-multibuild> patching script interpreter paths in /nix/store/yw7lfwmb664bns5xk3jg6196jj7zf3mw-flexbox-multibuild-0.1.0
flexbox-multibuild> stripping (with command strip and flags -S -p) in  /nix/store/yw7lfwmb664bns5xk3jg6196jj7zf3mw-flexbox-multibuild-0.1.0/bin
```

Does the Android build still works too?

```
> nix build -L .#aarch64-android.dev.flakebox-tutorial                        
warning: Git tree '/home/dpc/tmp/flakebox-tutorial' is dirty                          
flexbox-multibuild-deps> cargoArtifacts not set, will not reuse any cargo artifacts
flexbox-multibuild-deps> unpacking sources  
# ...
flexbox-multibuild> ++ command cargo build --profile dev --message-format json-render-diagnostics --locked
flexbox-multibuild>    Compiling flakebox-tutorial v0.1.0 (/build/source)
flexbox-multibuild>     Finished dev [unoptimized + debuginfo] target(s) in 0.09s
flexbox-multibuild> installing
flexbox-multibuild> patching script interpreter paths in /nix/store/q6ci1lg2xbaqvczn1s2y6wiw845a5559-flexbox-multibuild-0.1.0
flexbox-multibuild> stripping (with command strip and flags -S -p) in  /nix/store/q6ci1lg2xbaqvczn1s2y6wiw845a5559-flexbox-multibuild-0.1.0/bin
> file result/bin/flakebox-tutorial
result/bin/flakebox-tutorial: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, with debug_info, not stripped
```

Yes, it does!

Commit:

```
> git ci -a -m "Add some some dependencies"
```


and let's try the "cross shell".

## Cross-compilation dev shell

Remember: **when working locally you should use dev shells to
provide complete and reproducible development environment and
NOT invoke `nix build` for everything.**

While `nix build` and Nix derivations are great, they do introduce
an overhead and can't reason about your project as well as
`cargo` can.

But as things are currently, we can only compile our project
using native toolchain in dev shell, and we need to use `craneMultiBuild`
and `nix build` to cross-compile.

This is when so called "cross-shell" comes into play. The reason
the cross-shell is not a default shell is that - unlike `nix build .#<target>...` which
downloads toolchains on demand - it requires bringing in all the supported cross-compiling
toolchains upfront. This can cost gigabytes of downloaded data and storage,
while most developers for most projects will not need it.
