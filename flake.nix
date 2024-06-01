{
  inputs = {
    expidus.url = "github:ExpidusOS/expidus";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon/1b16e4290a5e4a59c75ef53617d597e02078791e";
  };

  outputs = {
    self,
    expidus,
    nixos-apple-silicon,
    ...
  }@inputs:
    expidus.lib.mkFlake {
      overlay = final: prev: {
        expidus = prev.expidus // {
          genesis-shell = prev.flutter.buildFlutterApplication {
            version = "0-unstable-git+${self.shortRev or "dirty"}";
            src = prev.lib.cleanSource self;

            pubspecLock = prev.lib.importJSON ./pubspec.lock.json;

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
              flutter yq cage
              wayland-utils
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
