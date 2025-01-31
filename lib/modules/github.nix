{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) types;
in
{
  options.github = {
    ci = {
      enable = lib.mkEnableOption "just integration" // {
        default = true;
      };

      cachixRepo = lib.mkOption {
        type = types.nullOr types.str;
        description = "Name of the cachix repository to use for cache";
        default = null;
      };

      flakeSelfCheck = {
        enable = lib.mkEnableOption "flake self-check" // {
          default = true;
        };
      };

      runsOn = lib.mkOption {
        type = types.anything;
        description = "Value of a runs-on to use for default Linu workflows (lint, self-check, etc.)";
        default = "ubuntu-latest";
      };

      buildOutputs = lib.mkOption {
        type = types.listOf types.str;
        description = "List of outputs to build";
        default = [ ];
      };

      buildMatrix = lib.mkOption {
        type = types.attrs;
        description = "Build matrix to use in the workflow `strategy.matrix` of `build` job";
        default = {
          host = [
            "macos-x86_64"
            "macos-aarch64"
            "linux"
          ];
          include = [
            {
              host = "linux";
              runs-on = config.github.ci.runsOn;
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
        };
      };

      buildMatrixExtra = lib.mkOption {
        type = types.attrs;
        description = "Additional build matrix to deep merge with `buildMatrix`";
        default = { };
      };

      workflows = lib.mkOption {
        default = { };
        description = ''
          Set of workflows to generate in `.github/workflows/`".
        '';

        type = types.attrsOf (
          types.submodule (
            {
              name,
              config,
              options,
              ...
            }:
            {
              options = {

                enable = lib.mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    Whether this workflow file should be generated. This
                    option allows specific workflow files to be disabled.
                  '';
                };

                content = lib.mkOption {
                  default = null;
                  type = types.attrsOf types.anything;
                  description = "Content of the workflow";
                };
              };
            }
          )
        );

        apply = value: lib.filterAttrs (n: v: v.enable == true) value;
      };
    };
  };

  config =
    let
      writeYaml = name: body: (pkgs.formats.yaml { }).generate "flakebox-${name}-yaml-gen" body;
      magicNixCacheStep = {
        name = "Magic Nix Cache";
        uses = "DeterminateSystems/magic-nix-cache-action@v2";
      };

      cachixCacheStep =
        { name }:
        {
          uses = "cachix/cachix-action@v12";
          "with" = {
            inherit name;
            authToken = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
          };
          continue-on-error = true;
        };

      flakebox-ci =
        {
          buildCmd,
          buildMatrix,
          cacheStep ? magicNixCacheStep,
        }:
        {
          name = "CI";

          on = {
            push = {
              branches = [
                "master"
                "main"
              ];
              tags = [ "v*" ];
            };
            pull_request = {
              branches = [
                "master"
                "main"
              ];
            };
            merge_group = {
              branches = [
                "master"
                "main"
              ];
            };
            workflow_dispatch = { };
          };

          jobs = lib.mkMerge [
            (lib.mkIf config.github.ci.flakeSelfCheck.enable {
              flake = {
                name = "Flake self-check";
                runs-on = config.github.ci.runsOn;
                steps = [
                  { uses = "actions/checkout@v4"; }
                  {
                    name = "Check Nix flake inputs";
                    uses = "DeterminateSystems/flake-checker-action@v5";
                    "with" = {
                      fail-mode = true;
                    };
                  }
                ];
              };
            })

            {
              lint = {
                name = "Lint";
                runs-on = config.github.ci.runsOn;
                steps = [
                  { uses = "actions/checkout@v4"; }

                  {
                    name = "Install Nix";
                    uses = "DeterminateSystems/nix-installer-action@v4";
                  }

                  cacheStep

                  {
                    name = "Cargo Cache";
                    uses = "actions/cache@v3";
                    "with" = {
                      path = "~/.cargo";
                      key = ''''${{ runner.os }}-''${{ hashFiles('Cargo.lock') }}'';
                    };
                  }

                  {
                    name = "Commit Check";
                    run = ''
                      # run the same check that git `pre-commit` hook does
                      nix develop --ignore-environment .#lint --command ./misc/git-hooks/pre-commit
                    '';
                  }
                ];
              };

              build = {
                name = "Build";
                strategy = {
                  matrix = buildMatrix;
                };
                runs-on = "\${{ matrix.runs-on }}";
                timeout-minutes = "\${{ matrix.timeout }}";
                steps = [
                  { uses = "actions/checkout@v4"; }

                  {
                    name = "Install Nix";
                    uses = "DeterminateSystems/nix-installer-action@v4";
                  }

                  cacheStep

                  {
                    name = "Build on \${{ matrix.host }}";
                    run = buildCmd;
                  }
                ];
              };
            }
          ];
        };
      flakebox-flakehub-publish = {
        name = "Publish to Flakehub";

        on = {
          push = {
            tags = [ "v?[0-9]+.[0-9]+.[0-9]+*" ];
          };
          workflow_dispatch = {
            inputs = {
              tags = {
                description = "The existing tag to publish to FlakeHub";
                type = "string";
                required = true;
              };
            };
          };
        };

        jobs = {
          flakehub-publish = {
            runs-on = config.github.ci.runsOn;
            permissions = {
              id-token = "write";
              contents = "read";
            };
            steps = [
              {
                uses = "actions/checkout@v4";
                "with" = {
                  ref = "\${{ (inputs.tag != null) && format('refs/tags/{0}', inputs.tag) || '' }}";
                };
              }

              {
                name = "Install Nix";
                uses = "DeterminateSystems/nix-installer-action@v4";
              }

              {
                name = "Flakehub Push";
                uses = "DeterminateSystems/flakehub-push@main";
                "with" = {
                  visibility = "public";
                  name = "\${{ github.repository }}";
                  tag = "\${{ inputs.tag }}";
                };
              }
            ];
          };
        };
      };

      recursiveMerge =
        attrList:
        let
          f =
            attrPath:
            lib.zipAttrsWith (
              n: values:
              if lib.tail values == [ ] then
                lib.head values
              else if lib.all lib.isList values then
                lib.unique (lib.concatLists values)
              else if lib.all lib.isAttrs values then
                f (attrPath ++ [ n ]) values
              else
                lib.last values
            );
        in
        f [ ] attrList;

    in
    lib.mkIf config.github.ci.enable {

      github.ci.workflows = {
        flakebox-ci = {
          content = flakebox-ci {
            buildCmd =
              if builtins.length config.github.ci.buildOutputs == 0 then
                ''
                  nix flake check -L .#
                ''
              else
                lib.strings.concatStringsSep "\n" (
                  builtins.map (output: "nix build -L ${output}") config.github.ci.buildOutputs
                );
            buildMatrix = recursiveMerge [
              config.github.ci.buildMatrix
              config.github.ci.buildMatrixExtra
            ];
            cacheStep =
              if config.github.ci.cachixRepo != null then
                cachixCacheStep { name = config.github.ci.cachixRepo; }
              else
                magicNixCacheStep;
          };
        };
        flakebox-flakehub-publish = {
          content = flakebox-flakehub-publish;
        };
      };

      rootDir = lib.mapAttrs' (
        k: v:
        let
          rawYamlFile = writeYaml k v.content;
        in
        lib.nameValuePair ".github/workflows/${k}.yml" {
          text = ''
            # THIS FILE IS AUTOGENERATED FROM FLAKEBOX CONFIGURATION

            ${builtins.readFile rawYamlFile}

            # THIS FILE IS AUTOGENERATED FROM FLAKEBOX CONFIGURATION
          '';
        }
      ) config.github.ci.workflows;
    };
}
