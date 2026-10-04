# anchor-overlay

[![CI](https://github.com/vaporif/anchor-overlay/actions/workflows/ci.yml/badge.svg)](https://github.com/vaporif/anchor-overlay/actions/workflows/ci.yml)

Pure, reproducible Nix packages for [Anchor](https://github.com/otter-sec/anchor) and [Solana](https://github.com/anza-xyz/agave) tooling. You get an overlay, a devshell, flake packages, and a builder for Anchor programs. You do not need rustup.

Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

## Quick start

```bash
nix develop github:vaporif/anchor-overlay
anchor --version
solana --version
```

## Packages

| Package | What it is |
|---------|------------|
| `anchor-cli` | Anchor CLI, built from source with Crane |
| `solana-rust` | Rust toolchain set up for Solana SBF builds |
| `solana-platform-tools` | Prebuilt Solana platform tools (LLVM, Rust, etc.) |
| `buildAnchorProgram` | Builds an Anchor program as a pure Nix derivation |

## Versions

Each Anchor version lives under `pkgs.anchor.<version>`. Top-level names point to the default.

| Version | Agave | Platform tools | SBPF arch |
|---------|-------|----------------|-----------|
| `1.2.0` (default) | 4.1.2 | v1.57 | v3 |
| `1.0.2` | 3.1.10 | v1.52 | legacy (`sbf-solana-solana`) |
| `0.32.1` | 2.3.13 | v1.52 | legacy (`sbf-solana-solana`) |

Anchor moved from `solana-foundation/anchor` to [`otter-sec/anchor`](https://github.com/otter-sec/anchor). Version `1.2.0` comes from the new repo.

```nix
pkgs.anchor."1.2.0".anchor-cli
pkgs.anchor."0.32.1".anchor-cli

pkgs.anchor-cli         # = pkgs.anchor."1.2.0".anchor-cli
pkgs.buildAnchorProgram # = pkgs.anchor."1.2.0".buildAnchorProgram
```

## Use in a flake

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
      # Dev shell with the default version
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.anchor-cli pkgs.solana-rust ];
      };

      # Dev shell with a specific version
      devShells.${system}.legacy = pkgs.mkShell {
        packages = with pkgs.anchor."0.32.1"; [ anchor-cli solana-rust ];
      };

      # Build the program with `nix build`
      packages.${system}.default = pkgs.buildAnchorProgram {
        pname = "my-program";
        src = ./.;
        cargoLock = { lockFile = ./Cargo.lock; };
      };

      # Same, with a specific version
      packages.${system}.legacy = pkgs.anchor."0.32.1".buildAnchorProgram {
        pname = "my-program";
        src = ./.;
        cargoLock = { lockFile = ./Cargo.lock; };
      };
    };
}
```

`buildAnchorProgram` needs no network access at build time. See [`test-apps/`](test-apps/) for full working examples.

## Overrides

### Platform tools

Use `withPlatformTools` to pick another platform-tools version. Supported: v1.48 to v1.57. v1.53+ only ship the `sbpf*` targets (v1.52 and older lack `sbpfv3`), so legacy `sbf-solana-solana` builds need ≤ v1.52 and SBPF v3 builds need ≥ v1.53.

```nix
# 1.0.2 with platform-tools v1.48 instead of v1.52
pkgs.anchor."1.0.2".withPlatformTools."v1.48".buildAnchorProgram {
  pname = "my-program";
  src = ./.;
  cargoLock = { lockFile = ./Cargo.lock; };
};
```

### SBPF architecture

Anchor 1.2.0 builds for SBPF v3 by default, which needs platform-tools v1.53 or newer. On the CLI, change it with `anchor build --arch <v0..v3>`. In Nix, pass `arch` to `buildAnchorProgram`:

```nix
pkgs.anchor."1.2.0".buildAnchorProgram {
  pname = "my-program";
  src = ./.;
  cargoLock = { lockFile = ./Cargo.lock; };
  arch = "v2"; # builds for sbpfv2-solana-solana
};
```

### Agave (SBF SDK)

Each version uses a fixed Agave release for the SBF SDK. Use `withAgave` to change it. Agave 4.x no longer ships `sbf-sdk`, so pass `sbfSdkUrl` pointing at `anza-xyz/cargo-build-sbf`.

```nix
pkgs.anchor."1.0.2".withAgave {
  agaveVersion = "2.3.13";
  sbfSdkHash = "sha256-zdGtFHxj/I4ID3RN3BNx27LakxzhwOuvSZpVb3M93YM=";
}

pkgs.anchor."1.2.0".withAgave {
  agaveVersion = "4.1.2";
  sbfSdkUrl = "https://github.com/anza-xyz/cargo-build-sbf/releases/download/sbf-sdk%40v4.3.0/sbf-sdk.tar.bz2";
  sbfSdkHash = "sha256-53Fq5OkvsMByKkn8zESnhx3YYi+vcRFesQVikU2rVNo=";
}

# Works together with withPlatformTools
pkgs.anchor."1.0.2".withPlatformTools."v1.48".withAgave {
  agaveVersion = "2.3.13";
  sbfSdkHash = "sha256-zdGtFHxj/I4ID3RN3BNx27LakxzhwOuvSZpVb3M93YM=";
}
```

### Other Anchor versions

`lib.mkAnchorPackages` builds any Anchor version the overlay does not include. Copy an entry from [`lib/versions.nix`](lib/versions.nix) as a starting point.

## License

MIT
