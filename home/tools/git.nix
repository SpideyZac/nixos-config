{
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; lib.mkAfter [
    git
  ];
}