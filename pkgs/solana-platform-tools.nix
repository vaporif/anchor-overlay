{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libgcc,
  zlib,
  openssl,
  version,
  archives,
  agaveVersion,
  sbfSdkHash,
}: let
  archive = archives.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  platformTools = stdenv.mkDerivation {
    pname = "solana-platform-tools";
    inherit version;
    src = fetchurl {
      url = "https://github.com/anza-xyz/platform-tools/releases/download/${version}/${archive.name}";
      inherit (archive) hash;
    };
    nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];
    buildInputs = lib.optionals stdenv.isLinux [libgcc.lib zlib openssl];
    autoPatchelfIgnoreMissingDeps = [
      "libpython3.10.so.1.0"
      "libpanel.so.6"
      "libncurses.so.6"
      "libtinfo.so.6"
      "libxml2.so.2"
      "liblzma.so.5"
    ];
    unpackPhase = ''
      mkdir -p $out
      tar -xjf $src -C $out
      find $out -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    '';
    dontBuild = true;
    dontInstall = true;
  };

  sbfSdk = stdenv.mkDerivation {
    pname = "solana-sbf-sdk";
    version = agaveVersion;
    src = fetchurl {
      url = "https://github.com/anza-xyz/agave/releases/download/v${agaveVersion}/sbf-sdk.tar.bz2";
      hash = sbfSdkHash;
    };
    unpackPhase = ''
      mkdir -p $out/dependencies
      tar -xjf $src -C $out
      ln -s ${platformTools} $out/dependencies/platform-tools
      [ -f "$out/sbf-sdk/env.sh" ] && ln -s $out/sbf-sdk/env.sh $out/env.sh || true
    '';
    dontBuild = true;
    dontInstall = true;
  };
in {
  inherit platformTools sbfSdk;
}
