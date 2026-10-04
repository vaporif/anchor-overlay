{
  pkgs,
  rust-bin,
  craneLib,
  versionConfig,
  platformToolsVersion ? versionConfig.platform-tools.version,
  agaveVersion ? versionConfig.platform-tools.agaveVersion,
  sbfSdkHash ? versionConfig.platform-tools.sbfSdk.hash,
  sbfSdkUrl ? versionConfig.platform-tools.sbfSdk.url or null,
  sbfArch ? versionConfig.platform-tools.arch or null,
}: let
  inherit (pkgs) callPackage;

  platformToolsVersions = import ./platform-tools-versions.nix;

  ptConfig = platformToolsVersions.${platformToolsVersion}
    or (throw "Unknown platform-tools version: ${platformToolsVersion}. Available: ${builtins.concatStringsSep ", " (builtins.attrNames platformToolsVersions)}");

  solana-platform-tools = callPackage ../pkgs/solana-platform-tools.nix {
    version = platformToolsVersion;
    inherit (ptConfig) archives;
    inherit agaveVersion sbfSdkHash sbfSdkUrl;
  };

  solana-rust = callPackage ../pkgs/solana-rust.nix {
    inherit solana-platform-tools;
  };

  anchor-cli = callPackage ../pkgs/anchor-cli.nix {
    inherit rust-bin solana-platform-tools sbfArch;
    crane = craneLib;
    anchorConfig = versionConfig.anchor;
  };

  agave-cli = callPackage ../pkgs/agave-cli.nix {inherit agaveVersion;};

  buildAnchorProgram = callPackage ../pkgs/buildAnchorProgram.nix {
    inherit solana-platform-tools anchor-cli sbfArch;
  };

  withPlatformTools =
    builtins.mapAttrs (
      ptVersion: _:
        import ./mkAnchorPackages.nix {
          inherit pkgs rust-bin craneLib versionConfig agaveVersion sbfSdkHash sbfSdkUrl sbfArch;
          platformToolsVersion = ptVersion;
        }
    )
    platformToolsVersions;
in {
  inherit anchor-cli solana-rust solana-platform-tools buildAnchorProgram agave-cli withPlatformTools;

  withAgave = {
    agaveVersion,
    sbfSdkHash,
    sbfSdkUrl ? null,
  }:
    import ./mkAnchorPackages.nix {
      inherit pkgs rust-bin craneLib versionConfig platformToolsVersion agaveVersion sbfSdkHash sbfSdkUrl sbfArch;
    };
}
