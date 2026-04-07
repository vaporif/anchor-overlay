{
  pkgs,
  rust-bin,
  craneLib,
  versionConfig,
}: let
  inherit (pkgs) lib stdenv callPackage;

  solana-platform-tools = callPackage ../pkgs/solana-platform-tools.nix {
    inherit (versionConfig.platform-tools) version archives;
    agaveVersion = versionConfig.platform-tools.agaveVersion;
    sbfSdkHash = versionConfig.platform-tools.sbfSdk.hash;
  };

  solana-rust = callPackage ../pkgs/solana-rust.nix {
    inherit solana-platform-tools;
  };

  solana-source = pkgs.fetchFromGitHub versionConfig.agave.src;

  solana-cli = callPackage ../pkgs/solana-cli.nix {
    inherit rust-bin solana-source solana-platform-tools;
    crane = craneLib;
    rustVersion = versionConfig.agave.rustVersion;
    solanaPkgs = versionConfig.agave.solanaPkgs;
  };

  anchor-cli = callPackage ../pkgs/anchor-cli.nix {
    inherit rust-bin solana-platform-tools;
    crane = craneLib;
    anchorConfig = versionConfig.anchor;
  };

  buildAnchorProgram = callPackage ../pkgs/buildAnchorProgram.nix {
    inherit solana-platform-tools solana-cli anchor-cli;
  };
in {
  inherit solana-cli anchor-cli solana-rust solana-platform-tools buildAnchorProgram;
}
