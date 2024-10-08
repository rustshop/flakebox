{
  lib,
  pkgs,
  config,
  ...
}:
{

  options.convco = {
    enable = lib.mkEnableOption "convco integration" // {
      default = true;
    };

    commit-msg = {
      enable = lib.mkEnableOption "convco git commit-msg hook" // {
        default = true;
      };
    };
  };

  config = lib.mkIf config.convco.enable {
    env.shellPackages = [
      pkgs.convco
    ];
    git.commit-msg.hooks = {
      convco = ''
        # Sanitize file first, by removing leading lines that are empty or start with a hash,
        # as `convco` currently does not do it automatically (but git will)
        # TODO: next release of convco should be able to do it automatically
        MESSAGE="$(
          while read -r line ; do
            # skip any initial comments (possibly from previous run)
            if [ -z "''${body_detected:-}" ] && { [[ "$line" =~ ^#.*$ ]] || [ "$line" == "" ]; }; then
              continue
            fi
            body_detected="true"

            echo "$line"
          done < "$1"
        )"

        # convco fails on fixup!, so remove fixup! prefix
        MESSAGE="''${MESSAGE#fixup! }"
        if ! convco check --from-stdin <<<"$MESSAGE" ; then
           >&2 echo "Please follow conventional commits(https://www.conventionalcommits.org)"
           >&2 echo "Use git commit <args> to fix your commit"
          exit 1
        fi
      '';
    };
  };
}
