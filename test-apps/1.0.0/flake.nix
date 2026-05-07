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
      buildArgs = {
        pname = "my-program";
        src = ./.;
        cargoLock = {lockFile = ./Cargo.lock;};
      };
    in {
      default = pkgs.anchor."1.0.0".buildAnchorProgram buildArgs;
      my-program = pkgs.anchor."1.0.0".buildAnchorProgram buildArgs;
    });

    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        buildInputs = [pkgs.openssl];
        nativeBuildInputs = [pkgs.pkg-config];
        packages =
          (with pkgs.anchor."1.0.0"; [
            anchor-cli
            solana-rust
          ])
          ++ pkgs.lib.optionals (builtins.elem system ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"]) [
            pkgs.anchor."1.0.0".agave-cli
          ];
      };
    });
  };
}
