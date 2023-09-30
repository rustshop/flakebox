# Tutorial: Building Rust with Nix in a new project


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
+              craneLib = (craneLib'.overrideArgs (prev: {
+                pname = "flexbox-multibuild";
+                src = rustSrc;
+              }));
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

Commit the current state and we I can explain in more details what is
this new Nix code doing and what else you can do with it (spoiler: cross-compilation and different cargo build profiles!).


```
> git add flake.nix❄️ ❄️ 
> git commit -a -m "Add initial build system"
Skipping semgrep check: .config/semgrep.yaml empty
[master e681b24] Add initial build system
 1 file changed, 30 insertions(+)
 ```
 
## Building Rust code with Flakebox (explanation & advanced)


WIP.

```
> nix build .#aarch64-android.dev.flakebox-tutorial
> file result/bin/flakebox-tutorial
result/bin/flakebox-tutorial: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, with debug_info, not stripped
```

Yes. This is our tutorial cross-compiled to aarch64 android. Just like that.
