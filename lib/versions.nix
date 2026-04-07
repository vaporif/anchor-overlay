{
  default-version = "1.0.0";

  "1.0.0" = {
    anchor = {
      src = {
        owner = "solana-foundation";
        repo = "anchor";
        tag = "v1.0.0";
        hash = "sha256-Y5452JSBAH+GkAJ57cDjup3vyMzPac+xvNAE+W81Ong=";
        fetchSubmodules = true;
      };
      patches = ["1.0.0.patch"];
      rustVersion = "1.86.0";
      idlRustVersion = "1.89.0";
    };

    platform-tools = {
      version = "v1.52";
      agaveVersion = "3.1.10";
      archives = {
        x86_64-darwin = {
          name = "platform-tools-osx-x86_64.tar.bz2";
          hash = "sha256-HdTysfe1MWwvGJjzfHXtSV7aoIMzM0kVP+lV5Wg3kdE=";
        };
        aarch64-darwin = {
          name = "platform-tools-osx-aarch64.tar.bz2";
          hash = "sha256-Fyffsx6DPOd30B5wy0s869JrN2vwnYBSfwJFfUz2/QA=";
        };
        x86_64-linux = {
          name = "platform-tools-linux-x86_64.tar.bz2";
          hash = "sha256-izhh6T2vCF7BK2XE+sN02b7EWHo94Whx2msIqwwdkH4=";
        };
        aarch64-linux = {
          name = "platform-tools-linux-aarch64.tar.bz2";
          hash = "sha256-sfhbLsR+9tUPZoPjUUv0apUmlQMVUXjN+0i9aUszH5g=";
        };
      };
      sbfSdk = {
        hash = "sha256-H+BQutp7cdju1C/ux6l+ZrzZpJtzkjza97czP7e35Ag=";
      };
    };
  };

  "0.32.1" = {
    anchor = {
      src = {
        owner = "solana-foundation";
        repo = "anchor";
        tag = "v0.32.1";
        hash = "sha256-oyCe8STDciRtdhOWgJrT+k50HhUWL2LSG8m4Ewnu2dc=";
        fetchSubmodules = true;
      };
      patches = ["0.32.1.patch"];
      rustVersion = "1.86.0";
      idlRustVersion = "1.89.0";
    };

    platform-tools = {
      version = "v1.52";
      agaveVersion = "3.1.6";
      archives = {
        x86_64-darwin = {
          name = "platform-tools-osx-x86_64.tar.bz2";
          hash = "sha256-HdTysfe1MWwvGJjzfHXtSV7aoIMzM0kVP+lV5Wg3kdE=";
        };
        aarch64-darwin = {
          name = "platform-tools-osx-aarch64.tar.bz2";
          hash = "sha256-Fyffsx6DPOd30B5wy0s869JrN2vwnYBSfwJFfUz2/QA=";
        };
        x86_64-linux = {
          name = "platform-tools-linux-x86_64.tar.bz2";
          hash = "sha256-izhh6T2vCF7BK2XE+sN02b7EWHo94Whx2msIqwwdkH4=";
        };
        aarch64-linux = {
          name = "platform-tools-linux-aarch64.tar.bz2";
          hash = "sha256-sfhbLsR+9tUPZoPjUUv0apUmlQMVUXjN+0i9aUszH5g=";
        };
      };
      sbfSdk = {
        hash = "sha256-4iV6NhfisZuLlwwhIi4OIbxj8Nzx+EFcG5cmK36fFAc=";
      };
    };
  };
}
