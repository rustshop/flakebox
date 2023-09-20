# Rustshop Flakebox - Rust dev experience (DX) we can share and love.

* Integrate best Rust dev tooling and practices into your project in seconds.
* Learn, customize, improve and share as a part of the DX-focused community.
* Keep up to date with the evolving ecosystem with ease.

Rustshop is a vision of how working with Rust could and should be like.
Flakebox is all you need to bring that vision into your Rust project.

Just because you're a lone Open Source developer working on a spare
time project doesn't mean you don't deserve a DX of a mature team
with dedicated tooling team. Just because you're a part of dedicated
tooling system in a mature team, doesn't mean you shouldn't benefit
from all the best ideas wider community has to offer.

**Warning:** Rustshop Flakebox is currently very immature. Expect
rought edges and some amount of churns before we figure out the
core pieces.

## Quick start

Flakebox leverages the power of Nix Flakes. Don't worry, you don't
have to know Nix to use it. But you do need to install Nix with Flake
support. We promise - this is the only requirement that you need to
take care of.

If you're new to Nix, we recommend using [Determinate Nix Installer](https://zero-to-nix.com/start/install),
which should come down to running:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

After you install Nix, you can boostrap Flakebox in any Rust project,
by running the following in its root directory:

```sh
nix run github:rustshop/flakebox#bootstrap
```

Then read the output and follow the instructions. There won't be many.