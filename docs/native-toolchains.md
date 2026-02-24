# Native toolchains

Flakebox features 3 toolchains corresponding to 3 `config.toolchain.channel.<name>` settings:

* `stable` - recent stable toolchain (`config.toolchain.stable` config)
* `nightly` - recent nightly toolchain (`config.toolchain.nightly` config)
* `default` - default toolchain, usually alias to `stable` or `nightly` (`config.toolchain.default`)

These toolchains are meant to be native target toolchains.

To change the default toolchain channel to nightly use:

```nix
flakeboxLib = flakebox.lib.mkLib pkgs {
  config = {
    toolchain.channel = "complete"; # or "latest", see https://github.com/nix-community/fenix for details
  };
};
```
