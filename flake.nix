{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, expidus-sdk }:
    let
      supportedSystems = builtins.attrNames expidus-sdk.packages;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import expidus-sdk { inherit system; });

      packagesFor = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          expidus-sdk-pkg = expidus-sdk.packages.${system}.default;
        in with pkgs; rec {
          nativeBuildInputs = [ meson ninja pkg-config vala glib expidus-sdk-pkg ];
          buildInputs = [ vadi libdevident libtokyo libpeas dbus ];
            # FIXME: add vapi (++ pkgs.lib.optional pkgs.stdenv.isLinux gtk-layer-shell;)
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
              maintainers = with expidus-sdk.lib.maintainers; [ TheComputerGuy ];
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
