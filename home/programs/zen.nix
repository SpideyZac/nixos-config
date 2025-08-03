{
  lib,
  system,
  inputs,
  ...
}:
{
  home.packages = lib.mkAfter [
    inputs.zen-browser.packages."${system}".default
  ];
}
