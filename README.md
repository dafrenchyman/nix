# Nix Configuration

This is my attempt at trying to build a bunch of reusable modules to make installing nixos (and nix-darwin) a bit easier for me.

This is far from perfect and needs a lot more cleanup and work.

Custom modules setup:

- `cloud_init.nix`: Helper to make it easier to setup cloud-init (so you can setup SSH keys and such through proxmox).
  - You'll need to install a cloud-init setup nixos installation for this to take effect on first boot. **Probably** fine...
- `gow_wolf.nix`: Helper to make it easy to setup [GOW Wolf](https://games-on-whales.github.io/wolf/stable/index.html)
- `gpu.nix`: Helper to make it easy to setup a GPU (currently only does AMD)

NOTES:

- The `setting-example.json` file is an example of what you will want in your own `settings.json` If you don't set a setting, it'll default to the defaults configured in `settings.nix`.
- `hardware-configuration.nix` is very much geared towards a [Snapraid](https://www.snapraid.it) array setup. It reads disk data from a `data.json` file (example can be found in `data-example.json`)

# Setup instructions

```bash
pre-commit install
```
