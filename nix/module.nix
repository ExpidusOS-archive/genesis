{ config, lib, pkgs, ... }:
{
  config = {
    services = {
      cage = {
        enable = true;
        program = "${lib.getExe pkgs.expidus.genesis-shell} --display-manager";
      };
      accounts-daemon.enable = true;
    };

    users.users.${config.services.cage.user} = {
      initialPassword = "123456";
      isNormalUser = true;
      extraGroups = [
        "dialout"
        "video"
        "wheel"
      ];
    };

    security.pam.services.genesis-shell = {
      allowNullPassword = true;
      startSession = true;
      enableGnomeKeyring = lib.mkDefault config.services.gnome.gnome-keyring.enable;
    };

    nix.enable = false;

    system.stateVersion = lib.version;
  };
}
