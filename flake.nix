{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-mobile = {
      url = "github:RossComputerGuy/mobile-nixos/fix/impure";
      flake = false;
    };
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon/1b16e4290a5e4a59c75ef53617d597e02078791e";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-mobile,
    nixos-apple-silicon,
    flake-utils,
    ...
  }@inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        isAsahi = pkgs.targetPlatform.isAarch64 && pkgs.stdenv.isLinux;

        overlay = f: s: {
          expidus = s.expidus // {
            genesis-shell = s.flutter.buildFlutterApplication {
              pname = "genesis-shell";
              version = "0-unstable-git+${self.shortRev or "dirty"}";

              src = lib.cleanSource self;

              buildInputs = with s; lib.optionalAttrs (stdenv.isLinux) [
                pam accountsservice polkit seatd wlroots_0_17 libdrm libGL libxkbcommon
                mesa vulkan-loader libdisplay-info libliftoff libinput xorg.xcbutilwm
                xorg.libX11 xorg.xcbutilerrors xorg.xcbutilimage xorg.xcbutilrenderutil
                libepoxy
              ];

              pubspecLock = lib.importJSON ./pubspec.lock.json;

              gitHashes = {
                libtokyo = "sha256-Zn30UmppXnzhs+t+EQNwAhaTPjCCxoN0a+AbH6bietg=";
                libtokyo_flutter = "sha256-Zn30UmppXnzhs+t+EQNwAhaTPjCCxoN0a+AbH6bietg=";
              };

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
        packages = {
          default = self.legacyPackages.${system}.expidus.genesis-shell;
        } // lib.optionalAttrs (isAsahi) {
          asahi = self.legacyPackages.${system}.pkgsAsahi.expidus.genesis-shell;
        };

        legacyPackages = pkgs.appendOverlays (lib.optionals (isAsahi) [
          (f: p: {
            pkgsAsahi = p.appendOverlays [
              nixos-apple-silicon.overlays.default
              (f: p: {
                mesa = p.mesa-asahi-edge;
              })
            ];
          })
        ] ++ [
          overlay
        ]);

        devShells = let 
          mkShell = pkgs: pkg: pkgs.mkShell {
            inherit (pkg) pname version name;
            inputsFrom = [ pkg ];
            packages = with pkgs; [
              flutter yq cage
              wayland-utils
              mesa-demos
            ];
          };

          pkgs = self.legacyPackages.${system};
        in {
          default = mkShell pkgs self.packages.${system}.default;
        } // lib.optionalAttrs (isAsahi) {
          asahi = mkShell pkgs.pkgsAsahi self.packages.${system}.asahi;
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
              configuration = { config, lib, ... }: {
                imports = [ ./nix/module.nix ];

                config = lib.mkIf (device == "pine64-pinephone") {
                  services.cage.environment.LIBGL_ALWAYS_SOFTWARE = "1";
                };
              };
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
