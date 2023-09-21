{ pkgs
}:
let
  lib = pkgs.lib;
  yaml = name: body: (pkgs.formats.yaml { }).generate name body;

  flakebox-ci = {
    name = "Continuous Integration";

    on = {
      push = {
        branches = [ "master" "main" ];
        tags = [ "v*" ];
      };
      pull_request = {
        branches = [ "master" "main" ];
      };
      merge_group = {
        branches = [ "master" "main" ];
      };
      workflow_dispatch = { };
    };

    jobs = {
      flake = {
        name = "Flake self-check";
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v4"; }
          {
            named = "Check Nix flake inputs";
            uses = "DeterminateSystems/flake-checker-action@v5";
            "with" = {
              fail-mode = true;
            };
          }
        ];
      };

      lint = {
        name = "Lint";
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v4"; }

          {
            name = "Install Nix";
            uses = "DeterminateSystems/nix-installer-action@v4";
          }
          {
            name = "Magic Nix Cache";
            uses = "DeterminateSystems/magic-nix-cache-action@v2";
          }

          {
            name = "Cargo Cache";
            uses = "actions/cache@v3";
            "with" = {
              path = "~/.cargo";
              key = ''
                ''${{ runner.os }}-''${{ hashFiles('Cargo.lock') }}
              '';
            };
          }

          {
            name = "Commit Check";
            run = ''
              # run the same check that git `pre-commit` hook does
              nix develop --ignore-environment .# --command ./misc/git-hooks/pre-commit
            '';
          }
        ];
      };
    };


    build = {
      name = "Build";
      runs-on = "ubuntu-latest";
      steps = [
        { uses = "actions/checkout@v4"; }

        {
          name = "Install Nix";
          uses = "DeterminateSystems/nix-installer-action@v4";
        }

        {
          name = "Magic Nix Cache";
          uses = "DeterminateSystems/magic-nix-cache-action@v2";
        }

        {
          name = "Build Flake";
          run = ''
            # run the same check that git `pre-commit` hook does
            nix flake check .#
          '';
        }
      ];
    };
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
        runs-on = "ubuntu-latest";
        steps = [
          {
            uses = "actions/checkout@v4";
            "with" = {
              ref = ''
                ''${{ (inputs.tag != null) && format('refs/tags/{0}', inputs.tag) || '''' }}
              '';
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

in
{
  workflows =
    {
      inherit flakebox-ci flakebox-flakehub-publish;
    };
}
