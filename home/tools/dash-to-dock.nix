{
  pkgs,
  lib,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.mkAfter [
      gnomeExtensions.dash-to-dock
    ];
}
