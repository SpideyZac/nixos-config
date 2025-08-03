{
  lib,
  ...
}:
{
  # Create a user for Zachary Lesser (zacml).
  # This user is a normal user and is part of the 'networkmanager' and 'wheel' groups. (root privileges)
  # The user is also added to the list of trusted users for Nix.
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
