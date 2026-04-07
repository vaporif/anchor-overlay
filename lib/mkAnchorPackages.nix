{
  pkgs,
  rust-bin,
  craneLib,
  versionConfig,
}: let
  inherit (pkgs) callPackage;

  solana-platform-tools = callPackage ../pkgs/solana-platform-tools.nix {
    inherit (versionConfig.platform-tools) version archives;
    agaveVersion = versionConfig.platform-tools.agaveVersion;
    sbfSdkHash = versionConfig.platform-tools.sbfSdk.hash;
  };

  solana-rust = callPackage ../pkgs/solana-rust.nix {
    inherit solana-platform-tools;
  };

  anchor-cli = callPackage ../pkgs/anchor-cli.nix {
    inherit rust-bin solana-platform-tools;
    crane = craneLib;
    anchorConfig = versionConfig.anchor;
  };

  buildAnchorProgram = callPackage ../pkgs/buildAnchorProgram.nix {
    inherit solana-platform-tools anchor-cli;
  };
in {
  inherit anchor-cli solana-rust solana-platform-tools buildAnchorProgram;
}
