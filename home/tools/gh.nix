{
  pkgs,
  lib,
  ...
}:
{
  # Import the gh package from Nixpkgs
  home.packages =
    with pkgs;
    lib.mkAfter [
      gh
    ];
}
