# Nivium

Plural genitive of _nix_. The NixOS and home-manager configuration set to configure Sharzy’s Nix-powered machines.

## Usage

To use NixOS modules,

```console
# nixos-build switch --flake .
```

Or use my own wrapper script of [nix-output-monitor](https://github.com/maralorn/nix-output-monitor),

```console
# nsw
```

The flake path is chosen from the automatically recognized hostname.

To use home-manager,
```console
$ nix run p#home-manager -- --switch --flake .#$(hostname)
```
