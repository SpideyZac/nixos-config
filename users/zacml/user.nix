{
  lib,
  ...
}:
{
  users.users.zacml = {
    isNormalUser = true;
    description = "Zachary Lesser";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  nix.settings.trusted-users = lib.mkAfter [ "zacml" ];
}
