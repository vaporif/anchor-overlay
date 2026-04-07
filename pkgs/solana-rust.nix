{
  stdenv,
  solana-platform-tools,
}:
stdenv.mkDerivation {
  pname = "solana-rust";
  version = solana-platform-tools.platformTools.version;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    for bin in cargo rustc; do
      ln -s ${solana-platform-tools.platformTools}/rust/bin/$bin $out/bin/$bin
    done
  '';
}
