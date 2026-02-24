{ pkgs, flakeboxLib }:
let
  inherit (pkgs) lib;
  mergeArgs = flakeboxLib.mergeArgs;

  assertEq =
    name: actual: expected:
    lib.assertMsg (
      actual == expected
    ) "${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  r1 = mergeArgs { buildInputs = [ 1 ]; } { buildInputs = [ 2 ]; };
  r2 = mergeArgs { nativeBuildInputs = [ 1 ]; } { nativeBuildInputs = [ 2 ]; };
  r3 = mergeArgs { packages = [ 1 ]; } { packages = [ 2 ]; };
  r4 =
    mergeArgs
      {
        env = {
          A = "1";
        };
      }
      {
        env = {
          B = "2";
        };
      };
  r5 =
    mergeArgs
      {
        env = {
          A = "1";
        };
      }
      {
        env = {
          A = "2";
        };
      };
  r6 = mergeArgs { } { buildInputs = [ 1 ]; };
  r7 = mergeArgs { buildInputs = [ 1 ]; } { };
  r8 = mergeArgs { } {
    env = {
      A = "1";
    };
  };
  r9 = mergeArgs {
    env = {
      A = "1";
    };
  } { };
  r10 = mergeArgs { foo = "left"; } { bar = "right"; };
  r11 = mergeArgs { foo = "left"; } { foo = "right"; };
in

assert assertEq "buildInputs merges both sides" r1.buildInputs [
  1
  2
];
assert assertEq "nativeBuildInputs merges both sides" r2.nativeBuildInputs [
  1
  2
];
assert assertEq "packages merges both sides" r3.packages [
  1
  2
];
assert assertEq "env merges both sides" r4.env {
  A = "1";
  B = "2";
};
assert assertEq "env right overrides left" r5.env { A = "2"; };
assert assertEq "buildInputs left missing" r6.buildInputs [ 1 ];
assert assertEq "buildInputs right missing" r7.buildInputs [ 1 ];
assert assertEq "env left missing" r8.env { A = "1"; };
assert assertEq "env right missing" r9.env { A = "1"; };
assert assertEq "plain attrs from both sides" r10.foo "left";
assert assertEq "plain attrs from both sides (bar)" r10.bar "right";
assert assertEq "plain attrs right overrides left" r11.foo "right";

pkgs.runCommand "mergeArgs-tests" { } "touch $out"
