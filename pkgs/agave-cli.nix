{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
  agaveVersion,
}: let
  platform =
    {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    }
    .${
      stdenv.hostPlatform.system
    }
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  hashes = {
    "2.3.13" = {
      "x86_64-unknown-linux-gnu" = "sha256-xDU5699pQkcui4djXW6lX0KKUePQIZ97b3IPxrGfreA=";
      "x86_64-apple-darwin" = "sha256-GAFrNS/fzS2/46A4dO8vxWsicPh4DUdPelhcgKO5BQ0=";
      "aarch64-apple-darwin" = "sha256-sgRfLCyoyXuCczutpsnBG0YZbBrNjwDjN0Kn0sIGChI=";
    };
    "3.1.10" = {
      "x86_64-unknown-linux-gnu" = "sha256-pyBf8pvPD3GZdAIl7K4rhaKOqWaIktXsIb2XSYgphKE=";
      "x86_64-apple-darwin" = "sha256-cHph7beo0ChVn9HdJ5ZtZ3dK1Ml6Yc1m7DCJ6KB9VCM=";
      "aarch64-apple-darwin" = "sha256-g5aT1AvdC9dtlWn33z04+zvGmqUCj8YL7zqpSO7kU6U=";
    };
  };
in
  stdenv.mkDerivation {
    pname = "agave-cli";
    version = agaveVersion;

    src = fetchurl {
      url = "https://github.com/anza-xyz/agave/releases/download/v${agaveVersion}/solana-release-${platform}.tar.bz2";
      hash = hashes.${agaveVersion}.${platform};
    };

    sourceRoot = "solana-release";

    nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];
    buildInputs = lib.optionals stdenv.isLinux [zlib stdenv.cc.cc.lib];

    installPhase = ''
      mkdir -p $out
      cp -r bin $out/
    '';
  }
