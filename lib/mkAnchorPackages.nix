{
  pkgs,
  rust-bin,
  craneLib,
  versionConfig,
  platformToolsVersion ? versionConfig.platform-tools.version,
}: let
  inherit (pkgs) callPackage;

  platformToolsVersions = import ./platform-tools-versions.nix;

  ptConfig = platformToolsVersions.${platformToolsVersion}
    or (throw "Unknown platform-tools version: ${platformToolsVersion}. Available: ${builtins.concatStringsSep ", " (builtins.attrNames platformToolsVersions)}");

  solana-platform-tools = callPackage ../pkgs/solana-platform-tools.nix {
    version = platformToolsVersion;
    inherit (ptConfig) archives;
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

  withPlatformTools =
    builtins.mapAttrs (
      ptVersion: _:
        import ./mkAnchorPackages.nix {
          inherit pkgs rust-bin craneLib versionConfig;
          platformToolsVersion = ptVersion;
        }
    )
    platformToolsVersions;
in {
  inherit anchor-cli solana-rust solana-platform-tools buildAnchorProgram withPlatformTools;
}
