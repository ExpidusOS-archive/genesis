{ config, lib, pkgs, ... }:
{
  config = {
    services = {
      cage = {
        enable = true;
        program = lib.getExe pkgs.expidus.genesis-shell;
      };
      accounts-daemon.enable = true;
    };

    users.users.${config.services.cage.user} = {
      initialPassword = "123456";
      isNormalUser = true;
    };

    security.pam.services.genesis-shell.text = lib.readFile ../linux/data/pam;

    nix.enable = false;

    system.stateVersion = lib.version;
  };
}
