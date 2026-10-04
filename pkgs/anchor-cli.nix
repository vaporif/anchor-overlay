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
  sbfArch ? null,
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
      export PATH="''${_NIX_IDL_TOOLCHAIN}/bin:$PATH"
      exec ''${_NIX_IDL_TOOLCHAIN}/bin/cargo "$@"
    fi
    # cargo parses "build-sbf" as "build" + "-sbf", so intercept and call directly
    if [[ "''${1:-}" == "build-sbf" || "''${1:-}" == "test-sbf" ]]; then
      subcmd="cargo-$1"
      shift
      exec "$subcmd" "$@"
    fi
    export PATH="''${_NIX_STABLE_TOOLCHAIN}/bin:$PATH"
    exec ''${_NIX_STABLE_TOOLCHAIN}/bin/cargo "$@"
  '';

  pt = solana-platform-tools.platformTools;

  sbfTarget = import ../lib/sbf-target.nix;

  # Thin cargo-build-sbf shim that uses platform-tools directly
  cargoBuildSbf = writeShellScriptBin "cargo-build-sbf" ''
    export PATH="${pt}/rust/bin:$PATH"
    MANIFEST_PATH=""
    TARGET="${sbfTarget sbfArch}"
    EXTRA_ARGS=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --manifest-path) MANIFEST_PATH="$2"; shift 2 ;;
        --no-rustup-override|--skip-tools-install) shift ;;
        --tools-version) shift 2 ;;
        --arch)
          case "$2" in
            ${lib.concatMapStringsSep "\n        " (a: ''${a}) TARGET="${sbfTarget a}" ;;'') ["v0" "v1" "v2" "v3" "v4"]}
            *) echo "cargo-build-sbf: unknown --arch '$2'" >&2; exit 1 ;;
          esac
          shift 2 ;;
        --) shift; EXTRA_ARGS+=("$@"); break ;;
        *) EXTRA_ARGS+=("$1"); shift ;;
      esac
    done
    if [ ! -d "${pt}/rust/lib/rustlib/$TARGET" ]; then
      echo "cargo-build-sbf: platform-tools ${pt.version} has no $TARGET target" >&2
      exit 1
    fi
    exec cargo build \
      ''${MANIFEST_PATH:+--manifest-path "$MANIFEST_PATH"} \
      --target "$TARGET" \
      --release \
      "''${EXTRA_ARGS[@]}"
  '';

  commonArgs = {
    pname = "anchor-cli";
    version = cleanVersion;
    src = patchedSrc;
    strictDeps = true;

    cargoExtraArgs = "--bin=anchor";

    nativeBuildInputs = [perl pkg-config makeWrapper];
    buildInputs = [openssl] ++ lib.optionals stdenv.hostPlatform.isLinux [udev];

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
        --prefix PATH : "${cargoBuildSbf}/bin:${cargoShim}/bin" \
        --set _NIX_IDL_TOOLCHAIN "${rustIdl}" \
        --set _NIX_STABLE_TOOLCHAIN "${rustStable}" \
        --set SBF_SDK_PATH "${solana-platform-tools.sbfSdk}"
    '';
  }
