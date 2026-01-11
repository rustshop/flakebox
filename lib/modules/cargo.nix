{ lib, config, ... }:
{

  options.cargo = {
    pre-commit = {
      cargo-lock.enable = lib.mkEnableOption "cargo lock check in pre-commit hook" // {
        default = true;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.cargo.pre-commit.cargo-lock.enable {
      git.pre-commit.hooks = {
        cargo_lock = ''
          # https://users.rust-lang.org/t/check-if-the-cargo-lock-is-up-to-date-without-building-anything/91048/5
          flakebox-in-each-cargo-workspace cargo update --workspace --locked -q
        '';
      };
    })
  ];
}
