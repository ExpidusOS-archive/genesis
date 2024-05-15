{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-mobile = {
      url = "github:RossComputerGuy/mobile-nixos/fix/impure";
      flake = false;
    };
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon/777e10ec2094a0ac92e61cbfe338063d1e64646e";
    flake-utils.url = "github:numtide/flake-utils";
    flutter-v322.url = "github:ExpidusOS/nixpkgs/feat/flutter-3.22.0";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-mobile,
    nixos-apple-silicon,
    flake-utils,
    flutter-v322,
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
          (f: p: rec {
            flutterPackages = p.recurseIntoAttrs (p.callPackages "${flutter-v322}/pkgs/development/compilers/flutter" {});
            flutter = flutterPackages.stable;
            flutter322 = flutterPackages.v3_22;
          })
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
        in {
          default = mkShell pkgs self.packages.${system}.default;
        } // lib.optionalAttrs (isAsahi) {
          asahi = mkShell self.legacyPackages.${system}.pkgsAsahi self.packages.${system}.asahi;
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
