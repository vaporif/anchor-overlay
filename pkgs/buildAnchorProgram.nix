{
  lib,
  stdenv,
  cargo,
  rustPlatform,
  solana-platform-tools,
  solana-cli,
  anchor-cli,
  jq,
}: {
  pname,
  src,
  cargoLock,
  version ? "0.1.0",
  programName ? pname,
  idl ? true,
  cargoExtraArgs ? [],
  env ? {},
}:
stdenv.mkDerivation ({
    inherit pname version src;

    nativeBuildInputs = [
      cargo
      rustPlatform.cargoSetupHook
      solana-cli
      anchor-cli
      jq
    ];

    cargoDeps = rustPlatform.importCargoLock cargoLock;

    dontStrip = true;

    buildPhase = let
      pt = solana-platform-tools;
      extraArgs = builtins.concatStringsSep " " cargoExtraArgs;
    in ''
      runHook preBuild

      # Build the SBF program using platform-tools rustc
      export SBF_SDK_PATH="${pt.sbfSdk}"
      export PATH="${pt.platformTools}/rust/bin:$PATH"

      cargo-build-sbf \
        --manifest-path programs/${programName}/Cargo.toml \
        --no-rustup-override \
        --skip-tools-install \
        ${extraArgs}

      runHook postBuild
    '';

    installPhase = let
      deployName = builtins.replaceStrings ["-"] ["_"] programName;
    in ''
      runHook preInstall

      mkdir -p $out

      # Copy the compiled SBF program
      cp target/deploy/${deployName}.so $out/

      # Copy the keypair if it exists
      if [ -f target/deploy/${deployName}-keypair.json ]; then
        cp target/deploy/${deployName}-keypair.json $out/
      fi

      ${lib.optionalString idl ''
        # Generate IDL using anchor's idl-build feature
        export ANCHOR_IDL_BUILD_PROGRAM_PATH="programs/${programName}"
        export ANCHOR_IDL_BUILD_RESOLUTION="TRUE"
        export ANCHOR_IDL_BUILD_NO_DOCS="FALSE"
        export ANCHOR_IDL_BUILD_SKIP_LINT="TRUE"
        export RUSTFLAGS="-A warnings"

        idl_output=$(cargo test \
          --manifest-path programs/${programName}/Cargo.toml \
          --features idl-build \
          --lib \
          __anchor_private_print_idl \
          -- \
          --show-output \
          --quiet \
          --test-threads=1 2>&1) || true

        idl_json=$(echo "$idl_output" | awk '
          BEGIN { in_program=0; program="" }
          /--- IDL begin program ---/ { in_program=1; next }
          /--- IDL end program ---/ { in_program=0; next }
          in_program { program = program $0 "\n" }
          END { printf "%s", program }
        ')

        if [ -n "$idl_json" ] && [ "$(echo "$idl_json" | tr -d '[:space:]')" != "" ]; then
          echo "$idl_json" | ${jq}/bin/jq . > $out/${deployName}.json
        fi
      ''}

      runHook postInstall
    '';
  }
  // env)
