{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    flake-utils,
    ...
  }@inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        overlay = f: s: {
          expidus = s.expidus // {
            genesis-shell = s.flutter.buildFlutterApplication {
              pname = "genesis-shell";
              version = "0-unstable-git+${self.shortRev or "dirty"}";

              src = lib.cleanSource self;

              buildInputs = with s; [ pam ];

              pubspecLock = lib.importJSON ./pubspec.lock.json;

              postInstall = ''
                mv $out/bin/genesis_shell $out/bin/genesis-shell
              '';

              meta = {
                mainProgram = "genesis-shell";
              };
            };
          };
        };
      in {
        packages.default = self.legacyPackages.${system}.expidus.genesis-shell;

        legacyPackages = pkgs.appendOverlays [
          overlay
        ];

        devShells.default = pkgs.mkShell {
          inherit (self.packages.${system}.default) pname version name;
          inputsFrom = [ self.packages.${system}.default ];
          packages = [ pkgs.flutter ];
        };
      })) // {
        nixosConfigurations = let
          mkQemu = system:
            let
              pkgs = self.legacyPackages.${system};
              inherit (nixpkgs) lib;
            in lib.nixosSystem {
              inherit system lib pkgs;

              modules = [
                "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
                ./nix/module.nix
                {
                  config = {
                    system.name = "qemu-${pkgs.targetPlatform.qemuArch}";
                    boot.kernelParams = lib.mkAfter [ "console=ttyS0" ];
                  };
                }
              ];
            };
        in {
          qemu-aarch64 = mkQemu "aarch64-linux";
          qemu-x86_64 = mkQemu "x86_64-linux";
        };
      };
}
