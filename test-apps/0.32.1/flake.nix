{
  description = "Solana Anchor test program";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    anchor-overlay.url = "path:../..";
  };

  outputs = {
    nixpkgs,
    anchor-overlay,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [anchor-overlay.overlays.default];
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.anchor."0.32.1".buildAnchorProgram {
        pname = "my-program";
        src = ./.;
        cargoLock = {lockFile = ./Cargo.lock;};
      };
    });

    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs.anchor."0.32.1"; [
          anchor-cli
        ];
      };
    });
  };
}
