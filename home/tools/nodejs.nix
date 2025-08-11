{
  pkgs,
  lib,
  ...
}:
{
  # Import the nodejs package from Nixpkgs
  home.packages =
    with pkgs;
    lib.mkAfter [
      nodejs
    ];
}
