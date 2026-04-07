{
  description = "Solana/Anchor tooling for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs = inputs: let
    versions = import ./lib/versions.nix;
    overlays = [inputs.rust-overlay.overlays.default inputs.self.overlays.default];
    perSystemPkgs = f:
      inputs.nixpkgs.lib.genAttrs (import inputs.systems) (
        system:
          f (import inputs.nixpkgs {
            inherit overlays system;
            config.allowUnfree = true;
          })
      );
  in {
    overlays.default = import ./overlay.nix {
      inherit (inputs) rust-overlay crane;
    };

    lib.mkAnchorPackages = import ./lib/mkAnchorPackages.nix;

    legacyPackages = perSystemPkgs (pkgs: pkgs.anchor);

    packages = perSystemPkgs (pkgs: let
      default = pkgs.anchor.${versions.default-version};
    in {
      inherit (default) anchor-cli solana-rust;
      default = default.anchor-cli;
    });

    devShells = perSystemPkgs (pkgs: let
      default = pkgs.anchor.${versions.default-version};
    in {
      default = pkgs.mkShell {
        packages = [
          default.anchor-cli
          default.solana-rust
          pkgs.nodejs
          pkgs.yarn
        ];
      };
    });

    formatter = perSystemPkgs (pkgs: pkgs.alejandra);
  };
}
