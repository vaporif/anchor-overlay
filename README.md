# anchor-overlay

[![CI](https://github.com/vaporif/anchor-overlay/actions/workflows/ci.yml/badge.svg)](https://github.com/vaporif/anchor-overlay/actions/workflows/ci.yml)

*Pure and reproducible* Nix packaging of [Anchor](https://github.com/solana-foundation/anchor) and [Solana](https://github.com/anza-xyz/agave) tooling. Provides an overlay, flake packages, and a builder function for compiling Anchor programs — no rustup required.

Supported platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

## Packages

| Package | Description |
|---------|-------------|
| `anchor-cli` | Anchor CLI, built from source with Crane |
| `solana-rust` | Rust toolchain configured for Solana BPF/SBF compilation |
| `solana-platform-tools` | Pre-built Solana platform tools (LLVM, Rust, etc.) |
| `buildAnchorProgram` | Builder function to compile Anchor programs as pure Nix derivations |

## Multi-version support

Multiple Anchor versions are available through the overlay under `pkgs.anchor.<version>`:

| Version | Anchor | Agave | Platform Tools (default) |
|---------|--------|-------|--------------------------|
| `1.0.0` (default) | 1.0.0 | 3.1.10 | v1.52 |
| `0.32.1` | 0.32.1 | 3.1.6 | v1.48 |

```nix
# Via overlay
pkgs.anchor."1.0.0".anchor-cli
pkgs.anchor."0.32.1".anchor-cli

# Top-level aliases point to the default version
pkgs.anchor-cli         # = pkgs.anchor."1.0.0".anchor-cli
pkgs.buildAnchorProgram # = pkgs.anchor."1.0.0".buildAnchorProgram
```

### Configurable platform-tools version

Each Anchor version ships with a default platform-tools version, but you can override it with `withPlatformTools`. Supported versions: v1.48 through v1.54.

```nix
# Use 0.32.1 with platform-tools v1.52 instead of the default v1.48
pkgs.anchor."0.32.1".withPlatformTools."v1.52".buildAnchorProgram {
  pname = "my-program";
  src = ./.;
  cargoLock = { lockFile = ./Cargo.lock; };
};

# Or in a devShell
pkgs.mkShell {
  packages = with pkgs.anchor."0.32.1".withPlatformTools."v1.52"; [
    anchor-cli
    solana-rust
  ];
};
```

## Installation

### Quick start

```bash
nix develop github:vaporif/anchor-overlay
anchor --version
solana --version
```

### Flake overlay

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    anchor-overlay.url = "github:vaporif/anchor-overlay";
  };

  outputs = { nixpkgs, anchor-overlay, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ anchor-overlay.overlays.default ];
      };
    in {
      devShells.${system} = {
        # Default version (1.0.0)
        default = pkgs.mkShell {
          packages = [
            pkgs.anchor-cli
            pkgs.solana-rust
          ];
        };

        # Specific version (0.32.1)
        legacy = pkgs.mkShell {
          packages = with pkgs.anchor."0.32.1"; [
            anchor-cli
            solana-rust
          ];
        };
      };
    };
}
```

## Building Anchor programs as Nix derivations

`buildAnchorProgram` compiles Anchor programs as pure Nix derivations. No network access at build time.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    anchor-overlay.url = "github:vaporif/anchor-overlay";
  };

  outputs = { nixpkgs, anchor-overlay, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ anchor-overlay.overlays.default ];
      };
    in {
      packages.${system} = {
        # Default version (1.0.0)
        default = pkgs.buildAnchorProgram {
          pname = "my-program";
          src = ./.;
          cargoLock = { lockFile = ./Cargo.lock; };
        };

        # Specific version (0.32.1)
        legacy = pkgs.anchor."0.32.1".buildAnchorProgram {
          pname = "my-program";
          src = ./.;
          cargoLock = { lockFile = ./Cargo.lock; };
        };
      };
    };
}
```

```bash
nix build
```

See [`test-apps/`](test-apps/) for complete working examples.

## Custom Anchor versions

Use `lib.mkAnchorPackages` to build any Anchor version not included in the overlay. Copy an existing entry from [`lib/versions.nix`](lib/versions.nix) as a template.

## License

MIT
