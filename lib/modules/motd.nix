{ lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.motd = {
    enable = lib.mkEnableOption "message of a day" // {
      default = false;
    };

    command = lib.mkOption {
      type = types.str;
      default = "";
      description = ''
        Command to execute to display motd
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.motd.enable {
      env.shellHooks = [
        ''
          yesterday=$(date -d "yesterday" +%s)
          motd_ts_path=".config/flakebox/tmp/motd"

          if [ ! -e "$motd_ts_path" ] || [ "$motd_ts_path" -ot "$yesterday" ]; then
          mkdir -p "$(dirname "$motd_ts_path")"
          touch "$motd_ts_path"
          ${config.motd.command}
          fi
        ''
      ];
    })
  ];
}
