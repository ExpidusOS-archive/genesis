{
  description = "The next generation desktop and mobile shell";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  inputs.gvc = {
    url = "git+https://gitlab.gnome.org/GNOME/libgnome-volume-control.git";
    flake = false;
  };

  inputs.gmobile = {
    url = "git+https://gitlab.gnome.org/guidog/gmobile.git?ref=main";
    flake = false;
  };

  inputs.libcall-ui = {
    url = "git+https://gitlab.gnome.org/World/Phosh/libcall-ui.git?ref=main";
    flake = false;
  };

  outputs = { self, expidus-sdk, gvc, gmobile, libcall-ui }:
    with expidus-sdk.lib;
    let
      unsupportedSystems = builtins.map (name: "${name}-cygwin") [ "i686" "x86_64" ];
      defaultSupported = lists.flatten (builtins.attrValues expidus.system.defaultSupported);
    in
    expidus.flake.makeOverride {
      self = expidus.flake.makeSubmodules self {
        "subprojects/gvc" = gvc;
        "subprojects/gmobile" = gmobile;
        "subprojects/libcall-ui" = libcall-ui;
      };
      name = "genesis-shell";
      sysconfig = expidus.system.make {
        supported = lists.subtractLists unsupportedSystems defaultSupported;
      };
    };
}
