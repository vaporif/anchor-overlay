{
  default-version = "1.0.2";

  "1.0.2" = {
    anchor = {
      src = {
        owner = "solana-foundation";
        repo = "anchor";
        tag = "v1.0.2";
        hash = "sha256-Y5452JSBAH+GkAJ57cDjup3vyMzPac+xvNAE+W81Ong=";
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
