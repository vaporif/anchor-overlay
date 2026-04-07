{
  rust-overlay,
  crane,
}: final: prev: let
  versions = import ./lib/versions.nix;
  mkAnchorPackages = import ./lib/mkAnchorPackages.nix;

  rust-bin = rust-overlay.lib.mkRustBin {} prev.buildPackages;
  craneLib = crane.mkLib prev;

  anchor = builtins.mapAttrs (
    version: config:
      mkAnchorPackages {
        pkgs = prev;
        inherit rust-bin craneLib;
        versionConfig = config;
      }
  ) (builtins.removeAttrs versions ["default-version"]);

  defaultPkgs = anchor.${versions.default-version};
in {
  inherit anchor;

  # Backwards-compatible top-level aliases from default version
  inherit (defaultPkgs) solana-cli anchor-cli solana-rust solana-platform-tools buildAnchorProgram;
}
