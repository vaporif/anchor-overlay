{
  default-version = "1.2.0";

  "1.2.0" = {
    anchor = {
      src = {
        owner = "otter-sec";
        repo = "anchor";
        tag = "v1.2.0";
        hash = "sha256-lbNAMEqRYkyRojs8r9pDZI36DTBzHuyP7LSvHd5cZi8=";
        fetchSubmodules = true;
      };
      patches = ["1.2.0.patch"];
      rustVersion = "1.99.0";
      idlRustVersion = "1.99.0";
    };

    platform-tools = {
      version = "v1.57";
      arch = "v3";
      agaveVersion = "4.1.2";
      sbfSdk = {
        # Agave 4.x no longer ships sbf-sdk; it moved to anza-xyz/cargo-build-sbf
        url = "https://github.com/anza-xyz/cargo-build-sbf/releases/download/sbf-sdk%40v4.1.0/sbf-sdk.tar.bz2";
        hash = "sha256-lD/+oNXvaUUXAWAboyglqUl4p1DQzvSBEvfdSA+8Ego=";
      };
    };
  };

  "1.0.2" = {
    anchor = {
      src = {
        owner = "solana-foundation";
        repo = "anchor";
        tag = "v1.0.2";
        hash = "sha256-J8q+oNT6x36LlTO/szlkxIcT5oFJ3y8b3YyqwBjDYX8=";
        fetchSubmodules = true;
      };
      patches = ["1.0.2.patch"];
      rustVersion = "1.88.0";
      idlRustVersion = "1.89.0";
    };

    platform-tools = {
      version = "v1.52";
      agaveVersion = "3.1.10";
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
      agaveVersion = "2.3.13";
      sbfSdk = {
        hash = "sha256-zdGtFHxj/I4ID3RN3BNx27LakxzhwOuvSZpVb3M93YM=";
      };
    };
  };
}
