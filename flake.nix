{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  outputs = { self, expidus-sdk }:
    with expidus-sdk.lib;
    expidus-sdk.lib.expidus.flake.makeOverride {
      inherit self;
      name = "genesis-shell";
      systems = lists.subtractLists (builtins.map (name: "${name}-cygwin") [ "i686" "x86_64" ]) (lists.flatten (builtins.attrValues expidus.system.defaultSupported));
    };
}
