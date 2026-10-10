# Eval-only tests, run by `nix flake check`.
pkgs: let
  inherit (pkgs) lib;
  sbfTarget = import ../lib/sbf-target.nix;

  evalsOk = x: (builtins.tryEval (builtins.deepSeq x x)).success;
  sbfSdkFor = version: args: (pkgs.anchor.${version}.withAgave args).solana-platform-tools.sbfSdk.drvPath;

  failures = lib.runTests {
    testSbfTargetLegacy = {
      expr = sbfTarget null;
      expected = "sbf-solana-solana";
    };
    testSbfTargetV0 = {
      expr = sbfTarget "v0";
      expected = "sbpf-solana-solana";
    };
    testSbfTargetV3 = {
      expr = sbfTarget "v3";
      expected = "sbpfv3-solana-solana";
    };

    testWithAgave4RequiresUrl = {
      expr = evalsOk (sbfSdkFor "1.2.1" {
        agaveVersion = "4.1.2";
        sbfSdkHash = lib.fakeHash;
      });
      expected = false;
    };
    testWithAgave4WithUrl = {
      expr = evalsOk (sbfSdkFor "1.2.1" {
        agaveVersion = "4.1.2";
        sbfSdkUrl = "https://example.invalid/sbf-sdk.tar.bz2";
        sbfSdkHash = lib.fakeHash;
      });
      expected = true;
    };
    testWithAgave3DefaultUrl = {
      expr = evalsOk (sbfSdkFor "1.0.2" {
        agaveVersion = "3.1.10";
        sbfSdkHash = lib.fakeHash;
      });
      expected = true;
    };
  };
in
  if failures == []
  then pkgs.runCommand "lib-tests" {} "touch $out"
  else throw "lib tests failed: ${builtins.toJSON failures}"
