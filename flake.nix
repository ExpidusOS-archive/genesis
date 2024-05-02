{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-mobile = {
      url = "github:RossComputerGuy/mobile-nixos/fix/impure";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-mobile,
    flake-utils,
    ...
  }@inputs:
    (flake-utils.lib.eachSystem (flake-utils.lib.defaultSystems ++ [ "riscv64-linux" ]) (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        overlay = f: s: {
          expidus = s.expidus // {
            genesis-shell = s.flutter.buildFlutterApplication {
              pname = "genesis-shell";
              version = "0-unstable-git+${self.shortRev or "dirty"}";

              src = lib.cleanSource self;

              buildInputs = with s; [ pam accountsservice polkit ];

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
          packages = [ pkgs.flutter pkgs.yq ];
        };
      })) // {
        nixosConfigurations = let
          mkSystem = modules: system:
            let
              pkgs = self.legacyPackages.${system};
              inherit (nixpkgs) lib;
            in lib.nixosSystem {
              inherit system lib pkgs;

              modules = modules ++ [
                ./nix/module.nix
              ];
            };

          mkMobileSystem = device: system:
            let
              pkgs = self.legacyPackages.${system};
              inherit (nixpkgs) lib;
            in import "${nixos-mobile}" {
              inherit system pkgs device;
              configuration = import ./nix/module.nix;
            };

          mkQemu = system: mkSystem [
            "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
            {
              config = {
                system.name = "qemu-${self.legacyPackages.${system}.targetPlatform.qemuArch}";
                boot.kernelParams = nixpkgs.lib.mkAfter [ "console=ttyS0" ];
              };
            }
          ] system;
        in {
          qemu-aarch64 = mkQemu "aarch64-linux";
          qemu-x86_64 = mkQemu "x86_64-linux";

          pine64-pinephone = mkMobileSystem "pine64-pinephone" "aarch64-linux";
        };
      };
}
