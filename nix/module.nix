{ config, lib, pkgs, ... }:
{
  config = {
    services.cage = {
      enable = true;
      program = lib.getExe pkgs.expidus.genesis-shell;
    };

    users.users.${config.services.cage.user} = {
      initialPassword = config.services.cage.user;
      isNormalUser = true;
    };

    nix.enable = false;

    system.stateVersion = lib.version;
  };
}
