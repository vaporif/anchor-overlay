{
  lib,
  stdenv,
  pkg-config,
  openssl,
  zlib,
  protobuf,
  perl,
  hidapi,
  udev,
  llvmPackages,
  makeWrapper,
  apple-sdk_15 ? null,
  rust-bin,
  crane,
  solana-source,
  solana-platform-tools,
  rustVersion ? "1.86.0",
  solanaPkgs ? [
    "cargo-build-sbf"
    "cargo-test-sbf"
    "solana"
    "solana-faucet"
    "solana-genesis"
    "solana-gossip"
    "solana-keygen"
    "solana-test-validator"
    "agave-install"
    "agave-validator"
  ],
}: let
  rust = rust-bin.stable.${rustVersion}.minimal.override {
    extensions = ["rust-src"];
  };

  craneLib = crane.overrideToolchain rust;

  commonArgs = {
    pname = "solana-cli";
    version = solana-source.rev or "unknown";
    src = solana-source;
    strictDeps = true;

    cargoExtraArgs = builtins.concatStringsSep " " (map (n: "--bin=${n}") solanaPkgs);

    nativeBuildInputs = [pkg-config protobuf perl llvmPackages.clang makeWrapper];

    buildInputs =
      [openssl zlib llvmPackages.libclang.lib]
      ++ lib.optionals stdenv.isLinux [hidapi udev]
      ++ lib.optionals stdenv.isDarwin [apple-sdk_15];

    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
    OPENSSL_NO_VENDOR = 1;

    BINDGEN_EXTRA_CLANG_ARGS = toString ([
        "-isystem ${llvmPackages.libclang.lib}/lib/clang/${lib.getVersion llvmPackages.clang}/include"
      ]
      ++ lib.optionals stdenv.isLinux ["-isystem ${stdenv.cc.libc.dev}/include"]
      ++ lib.optionals stdenv.isDarwin ["-isystem ${stdenv.cc.libc}/include"]);

    preBuild = lib.optionalString stdenv.isLinux ''
      export CXXFLAGS="-include cstdint ''${CXXFLAGS:-}"
    '';

    doCheck = false;
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;

      postInstall = let
        pt = solana-platform-tools;
      in ''
        wrapProgram $out/bin/cargo-build-sbf \
          --prefix PATH : "${pt.platformTools}/rust/bin" \
          --set SBF_SDK_PATH "${pt.sbfSdk}" \
          --add-flags "--no-rustup-override" \
          --add-flags "--skip-tools-install"

        wrapProgram $out/bin/cargo-test-sbf \
          --prefix PATH : "${pt.platformTools}/rust/bin" \
          --set SBF_SDK_PATH "${pt.sbfSdk}" \
          --add-flags "--no-rustup-override" \
          --add-flags "--skip-tools-install"
      '';

      meta = {
        description = "Solana CLI tools (Agave)";
        homepage = "https://github.com/anza-xyz/agave";
        license = lib.licenses.asl20;
        platforms = lib.platforms.unix;
      };
    })
