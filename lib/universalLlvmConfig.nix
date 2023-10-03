# universal `llvm-config` binary that will redirect calls
# to `LLVM_CONFIG_PATH_<target>` where target is sourced
# from env variables set either by caller or cargo calling
# build.rs script itself
{ pkgs }:
pkgs.writeShellScriptBin "llvm-config" ''
  if [ -n "''${TARGET:-}" ]; then
    env_name="LLVM_CONFIG_PATH_''${TARGET//-/_}"
    exec "''${!env_name}" "$@"
  elif [ -n "''${CARGO_BUILD_TARGET:-}" ]; then
    env_name="LLVM_CONFIG_PATH_''${CARGO_BUILD_TARGET//-/_}"
    exec "''${!env_name}" "$@"
  else
    exec llvm-config "$@"
  fi
''
