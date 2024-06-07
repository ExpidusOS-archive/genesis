{
  inputs = {
    expidus.url = "github:ExpidusOS/expidus";
    nixpkgs-flutter-engine.url = "github:ExpidusOS/nixpkgs/flutter-engine/init";
    zig = {
      url = "github:MidstallSoftware/zig/expidus";
      inputs = {
        nixpkgs.follows = "expidus/nixpkgs";
        flake-utils.follows = "expidus/flake-utils";
      };
    };
    zon2nix = {
      url = "github:MidstallSoftware/zon2nix/expidus";
      inputs.nixpkgs.follows = "expidus/nixpkgs";
    };
  };

  outputs = {
    self,
    expidus,
    nixpkgs-flutter-engine,
    zig,
    zon2nix,
    ...
  }@inputs:
    expidus.lib.mkFlake {
      overlay = final: prev: {
        zig = prev.zig_0_12.overrideAttrs (f: p: {
          version = "0.12.0-dev.${zig.shortRev or "dirty"}";
          src = zig;
        });

        flutterPackages = prev.recurseIntoAttrs (prev.callPackages "${nixpkgs-flutter-engine}/pkgs/development/compilers/flutter" {});
        flutter = final.flutterPackages.stable;
        flutter322 = final.flutterPackages.v3_22;

        zon2nix = prev.stdenv.mkDerivation {
          pname = "zon2nix";
          version = "0.1.2";

          src = zon2nix;

          nativeBuildInputs = [
            final.zig.hook
          ];

          zigBuildFlags = [
            "-Dnix=${prev.lib.getExe prev.nix}"
          ];

          zigCheckFlags = [
            "-Dnix=${prev.lib.getExe prev.nix}"
          ];
        };

        expidus = prev.expidus // {
          genesis-shell = final.flutter.buildFlutterApplication {
            version = "0-unstable-git+${self.shortRev or "dirty"}";
            src = prev.lib.cleanSource self;

            pubspecLock = prev.lib.importJSON ./pubspec.lock.json;

            nativeBuildInputs = [ final.zig ];

            gitHashes = {
              libtokyo = "sha256-ei3bgEdmmWz0iwMUBzBndYPlvNiCrDBrG33/n8PrBPI=";
              libtokyo_flutter = "sha256-ei3bgEdmmWz0iwMUBzBndYPlvNiCrDBrG33/n8PrBPI=";
            };

            inherit (prev.expidus.genesis-shell) pname buildInputs postInstall meta;
          };
        };
      };

      mkShells = self:
        let
          inherit (self.legacyPackages) lib;
          mkShell = pkgs: pkg: pkgs.mkShell {
            inherit (pkg) pname version name;
            inputsFrom = [ pkg ];
            packages = with pkgs; [
              flutter pkgs.zig pkgs.zon2nix
              yq cage wayland-utils
              mesa-demos
            ];
          };
        in {
          default = mkShell self.legacyPackages self.packages.default;
        } // lib.optionalAttrs (self.legacyPackages.isAsahi) {
          asahi = mkShell self.legacyPackages.pkgsAsahi self.packages.asahi;
        };

      mkPackages = self: {
        default = self.legacyPackages.expidus.genesis-shell;
      } // self.legacyPackages.lib.optionalAttrs (self.legacyPackages.isAsahi) {
        asahi = self.legacyPackages.pkgsAsahi.expidus.genesis-shell;
      };
    };
}
