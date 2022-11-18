{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  outputs = { self, expidus-sdk }:
    expidus-sdk.libExpidus.flake.makeOverride {
      inherit self;
      name = "genesis-shell";
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"

        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
