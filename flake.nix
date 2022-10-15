{
  description = "The next generation desktop and mobile shell";

  inputs.vadi = {
    url = github:ExpidusOS/Vadi/feat/nix;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.libdevident = {
    url = github:ExpidusOS/libdevident;
    inputs.expidus-sdk.follows = "expidus-sdk";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.vadi.follows = "vadi";
  };

  inputs.libtokyo = {
    url = path:subprojects/libtokyo;
    inputs.expidus-sdk.follows = "expidus-sdk";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.vadi.follows = "vadi";
  };

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vadi, libdevident, libtokyo, expidus-sdk }:
    let
      supportedSystems = builtins.attrNames libtokyo.packages;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      packagesFor = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          libdevident-pkg = libdevident.packages.${system}.default;
          vadi-pkg = vadi.packages.${system}.default;
          libtokyo-pkg = libtokyo.packages.${system}.default;
          expidus-sdk-pkg = expidus-sdk.packages.${system}.default;
        in with pkgs; rec {
          nativeBuildInputs = [ meson ninja pkg-config vala glib expidus-sdk-pkg ];
          buildInputs = [ vadi-pkg libdevident-pkg libtokyo-pkg libpeas ]
            ++ pkgs.lib.optional pkgs.stdenv.isLinux [ gtk-layer-shell ];
          propagatedBuildInputs = buildInputs;
        });
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          packages = packagesFor.${system};
        in
        {
          default = pkgs.stdenv.mkDerivation rec {
            name = "genesis-shell";
            src = self;
            outputs = [ "out" "devdoc" "dev" ];

            enableParallelBuilding = true;
            inherit (packages) nativeBuildInputs buildInputs propagatedBuildInputs;

            meta = with pkgs.lib; {
              homepage = "https://github.com/ExpidusOS/genesis";
              license = with licenses; [ gpl3Only ];
              maintainers = [ "Tristan Ross" ];
            };
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          packages = packagesFor.${system};
        in
        {
          default = pkgs.mkShell {
            packages = packages.nativeBuildInputs ++ packages.buildInputs;
          };
        });
    };
}
