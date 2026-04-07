{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  openssl,
  perl,
  udev,
  makeWrapper,
  writeShellScriptBin,
  symlinkJoin,
  rust-bin,
  crane,
  solana-platform-tools,
  anchorConfig,
}: let
  anchorVersion = anchorConfig.src.tag;
  cleanVersion = lib.removePrefix "v" anchorVersion;

  rustStable = rust-bin.stable.${anchorConfig.rustVersion}.minimal.override {
    extensions = ["rust-src"];
  };

  rustIdl = rust-bin.stable.${anchorConfig.idlRustVersion}.minimal.override {
    extensions = ["rust-src"];
  };

  craneLib = crane.overrideToolchain rustStable;

  patchedSrc = let
    originalSrc = fetchFromGitHub anchorConfig.src;
  in
    stdenv.mkDerivation {
      name = "anchor-cli-patched-${cleanVersion}";
      src = originalSrc;
      phases = ["unpackPhase" "patchPhase" "installPhase"];
      patches = map (p: ../patches/anchor-cli/${p}) anchorConfig.patches;
      installPhase = ''
        mkdir -p $out
        cp -r ./* $out/
      '';
    };

  cargoShim = writeShellScriptBin "cargo" ''
    if [[ "''${1:-}" == +* ]]; then
      shift
      exec ''${_NIX_IDL_TOOLCHAIN}/bin/cargo "$@"
    fi
    exec ''${_NIX_STABLE_TOOLCHAIN}/bin/cargo "$@"
  '';

  commonArgs = {
    pname = "anchor-cli";
    version = cleanVersion;
    src = patchedSrc;
    strictDeps = true;

    cargoExtraArgs = "--bin=anchor";

    nativeBuildInputs = [perl pkg-config makeWrapper];
    buildInputs = [openssl] ++ lib.optionals stdenv.isLinux [udev];

    OPENSSL_NO_VENDOR = 1;
    doCheck = false;

    meta = {
      description = "Solana Anchor Framework CLI";
      homepage = "https://github.com/${anchorConfig.src.owner}/${anchorConfig.src.repo}";
      license = lib.licenses.asl20;
      mainProgram = "anchor";
    };
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  anchor-unwrapped = craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;
    });
in
  symlinkJoin {
    name = "anchor-cli-${cleanVersion}";
    paths = [anchor-unwrapped];
    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/anchor \
        --prefix PATH : "${cargoShim}/bin" \
        --set _NIX_IDL_TOOLCHAIN "${rustIdl}" \
        --set _NIX_STABLE_TOOLCHAIN "${rustStable}" \
        --set SBF_SDK_PATH "${solana-platform-tools.sbfSdk}"
    '';
  }
