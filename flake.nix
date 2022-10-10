{
  description = "The next generation desktop and mobile shell";

  inputs.vadi = {
    url = github:ExpidusOS/Vadi/feat/nix;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.libtokyo = {
    url = path:./subprojects/libtokyo;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vadi, libtokyo, expidus-sdk }:
    let
      supportedSystems = builtins.attrNames libtokyo.packages;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      packagesFor = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          vadi-pkg = vadi.packages.${system}.default;
          libtokyo-pkg = libtokyo.packages.${system}.default;
          expidus-sdk-pkg = expidus-sdk.packages.${system}.default;
        in with pkgs; {
          nativeBuildInputs = [ meson ninja pkg-config vala glib expidus-sdk-pkg ];
          buildInputs = [ vadi-pkg libtokyo-pkg ];
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
            inherit (packages) nativeBuildInputs buildInputs;

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
