# Rust target triple for an SBPF arch, mirroring cargo-build-sbf's rust_target_triple.
# null keeps the legacy triple used by pre-1.2 anchor builds.
arch:
if arch == null
then "sbf-solana-solana"
else if arch == "v0"
then "sbpf-solana-solana"
else "sbpf${arch}-solana-solana"
