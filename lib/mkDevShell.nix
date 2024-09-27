{
  pkgs,
  flakeboxBin,
  config,
  root,
  docs,
  mkFenixToolchain,
  mkStdTargets,
  lib,
  mergeArgs,
}:
let
  rustfmt = config.toolchain.rustfmt;
in
{
  packages ? [ ],
  stdenv ? pkgs.stdenv,
  targets ? lib.getAttrs [ "default" ] (mkStdTargets { }),
  toolchain ? mkFenixToolchain {
    channel = config.toolchain.channel;
    components = config.toolchain.components;
    inherit targets;
  },
  ...
}@args:
let
  cleanedArgs = removeAttrs args [
    "toolchain"
    "packages"
    "targets"
  ];
in
let
  mkShell =
    if toolchain ? stdenv then pkgs.mkShell.override { stdenv = toolchain.stdenv; } else pkgs.mkShell;
  flakeboxInit =
    if config.flakebox.init.enable then
      ''
        flakebox init
      ''
    else
      "";

  args = mergeArgs cleanedArgs {
    packages =
      packages
      ++ [
        flakeboxBin

        (toolchain.toolchain)

        rustfmt

        pkgs.nodePackages.bash-language-server

        # This is required to prevent a mangled bash shell in nix develop
        # see: https://discourse.nixos.org/t/interactive-bash-with-nix-develop-flake/15486
        (pkgs.hiPrio pkgs.bashInteractive)

      ]
      ++ config.env.shellPackages
      ++ (builtins.attrValues {
        # Core & generic
        inherit (pkgs)
          git
          coreutils
          parallel
          shellcheck
          ;
        # Nix
        inherit (pkgs) nixfmt-rfc-style nil;
        # Rust tools
        inherit (pkgs) cargo-watch;
        # TODO: make conditional on `config.just.enable`
        inherit (pkgs) just;
      })
      ++ toolchain.toolchain.packages or [ ];

    buildInputs =
      lib.optionals pkgs.stdenv.isDarwin [
        pkgs.libiconv
        pkgs.darwin.apple_sdk.frameworks.Security
      ]
      ++ toolchain.toolchain.buildInputs or [ ];

    nativeBuildInputs = toolchain.toolchain.nativeBuildInputs or [ ];

    JUST_UNSTABLE = "true";

    shellHook = ''
      # set the root dir
      git_root="$(git rev-parse --show-toplevel)"
      export FLAKEBOX_ROOT_DIR_CANDIDATE=${root}
      export FLAKEBOX_PROJECT_ROOT_DIR="''${git_root:-$PWD}"
      export PATH="''${git_root}/.config/flakebox/bin/:''${PATH}"

      if [ -e "''${FLAKEBOX_PROJECT_ROOT_DIR}/.config/flakebox/shellHook.sh" ]; then
        source "''${FLAKEBOX_PROJECT_ROOT_DIR}/.config/flakebox/shellHook.sh"
      fi

      ${flakeboxInit}

      ${cleanedArgs.shellHook or ""}
    '';
  };
in
mkShell (mergeArgs (mergeArgs toolchain.commonArgs toolchain.shellArgs) args)
