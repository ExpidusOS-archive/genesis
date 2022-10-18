{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  outputs = { self, expidus-sdk }:
    {
      overlays.default = final: prev: {
        genesis-shell = (prev.genesis-shell.overrideAttrs (old: {
          version = self.rev or "dirty";
          src = builtins.path { name = "genesis-shell"; path = prev.lib.cleanSource ./.; };
          nativeBuildInputs = old.nativeBuildInputs ++ [ prev.wrapGAppsHook ];
          buildInputs = old.buildInputs ++ [ prev.gsettings-desktop-schemas ];
        }));
      };

      packages = expidus-sdk.lib.forAllSystems (system:
        let
          pkgs = expidus-sdk.lib.nixpkgsFor.${system};
        in {
          default = (self.overlays.default pkgs pkgs).genesis-shell;
        });

      devShells = expidus-sdk.lib.forAllSystems (system:
        let
          pkgs = expidus-sdk.lib.nixpkgsFor.${system};
          pkg = self.packages.${system}.default;
        in
        {
          default = pkgs.mkShell {
            packages = pkg.nativeBuildInputs ++ pkg.buildInputs;
          };
        });
    };
}
