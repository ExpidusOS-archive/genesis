{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  outputs = { self, expidus-sdk }:
    expidus-sdk.libExpidus.flake.makeOverride {
      inherit self;
      name = "genesis-shell";
    };
}
