# Native Toolchains

Flakebox features 3 toolchains corresponding to 3 `config.toolchain.channel.<name>` settings:

Toolchain short-names:

* `stable` - recent stable toolchain (`config.toolchain.stable` config)
* `nightly` - recent nightly toolchain (`config.toolchain.nightly` config)
* `default` - default toolchain, usually alias to `stable` or `nightly` (`config.toolchain.default`)

These toolchains are meant to be native target toolchains.

To change the default toolchain to nightly use:

```nix
flakeboxLib = flakebox.lib.${system} {
  config = {
    toolchain.channel.default = "nightly";
  };
};
```
