{
  pkgs,
  lib,
  ...
}:
{
  # Import the dash-to-dock extension from Nixpkgs
  home.packages =
    with pkgs;
    lib.mkAfter [
      gnomeExtensions.dash-to-dock
    ];
}
