{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  outputs = { self, expidus-sdk }: expidus-sdk.lib.mkFlake { inherit self; name = "genesis-shell"; };
}
