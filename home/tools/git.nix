{
  pkgs,
  lib,
  ...
}:
{
  # Import the git package from Nixpkgs
  home.packages =
    with pkgs;
    lib.mkAfter [
      git
    ];
}
